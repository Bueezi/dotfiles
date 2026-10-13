// tray-spacer [N]: N empty icons in the X tray (XEmbed), always at its far end. i3bar's
// `padding` leaves the tray at the screen's edge, inside the tablet's round corner; it sorts tray
// icons by window class, and "~spacer" sorts after every app, so the real icons sit left of these.
// Docks again when the tray comes back (i3bar restarts on an i3 reload). Built by termux.sh.
#include <X11/Xatom.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

static Atom tray_sel, opcode, manager;

static void dock(Display *d, Window *icons, int n) {
    Window tray;
    while ((tray = XGetSelectionOwner(d, tray_sel)) == None)
        sleep(1);
    for (int i = 0; i < n; i++) {
        XEvent ev = {0};
        ev.xclient.type = ClientMessage;
        ev.xclient.window = tray;
        ev.xclient.message_type = opcode;
        ev.xclient.format = 32;
        ev.xclient.data.l[0] = CurrentTime;
        ev.xclient.data.l[1] = 0;   // SYSTEM_TRAY_REQUEST_DOCK
        ev.xclient.data.l[2] = icons[i];
        XSendEvent(d, tray, False, NoEventMask, &ev);
    }
    XSync(d, False);
}

int main(int argc, char **argv) {
    int n = argc > 1 ? atoi(argv[1]) : 1;
    Display *d = XOpenDisplay(NULL);
    if (!d || n < 1)
        return 1;
    int s = DefaultScreen(d);
    Window root = RootWindow(d, s);
    char name[32];
    snprintf(name, sizeof name, "_NET_SYSTEM_TRAY_S%d", s);
    tray_sel = XInternAtom(d, name, False);
    opcode = XInternAtom(d, "_NET_SYSTEM_TRAY_OPCODE", False);
    manager = XInternAtom(d, "MANAGER", False);
    Atom info_atom = XInternAtom(d, "_XEMBED_INFO", False);

    // The tray's own visual (i3bar --transparency: 32-bit), to paint the bar's see-through black
    Window tray;
    while ((tray = XGetSelectionOwner(d, tray_sel)) == None)
        sleep(1);
    Visual *visual = DefaultVisual(d, s);
    int depth = DefaultDepth(d, s);
    Atom type;
    int format, count;
    unsigned long items, after;
    unsigned char *data = NULL;
    if (XGetWindowProperty(d, tray, XInternAtom(d, "_NET_SYSTEM_TRAY_VISUAL", False), 0, 1, False,
                           XA_VISUALID, &type, &format, &items, &after, &data) == Success && data && items) {
        XVisualInfo want = {.visualid = ((unsigned long *)data)[0]}, *got;
        if ((got = XGetVisualInfo(d, VisualIDMask, &want, &count))) {
            visual = got->visual;
            depth = got->depth;
        }
    }
    // The bar's #000000b3 (wm/i3) as a premultiplied 32-bit pixel; plain black without transparency
    XSetWindowAttributes attr = {
        .background_pixel = depth == 32 ? 0xb3000000 : 0, .border_pixel = 0,
        .colormap = XCreateColormap(d, root, visual, AllocNone)};

    Window *icons = calloc(n, sizeof(Window));
    XClassHint class = {"~spacer", "~spacer"};
    long info[2] = {0, 1};   // XEmbed version 0, XEMBED_MAPPED
    for (int i = 0; i < n; i++) {
        icons[i] = XCreateWindow(d, root, 0, 0, 16, 16, 0, depth, InputOutput, visual,
                                 CWBackPixel | CWBorderPixel | CWColormap, &attr);
        XSetClassHint(d, icons[i], &class);
        XChangeProperty(d, icons[i], info_atom, info_atom, 32, PropModeReplace, (unsigned char *)info, 2);
    }
    // A new tray announces itself with a MANAGER message on the root window
    XSelectInput(d, root, StructureNotifyMask);
    dock(d, icons, n);
    for (XEvent ev;;) {
        XNextEvent(d, &ev);
        if (ev.type == ClientMessage && ev.xclient.message_type == manager)
            dock(d, icons, n);
    }
}
