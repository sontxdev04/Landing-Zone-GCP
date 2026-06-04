#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Generate ONE polished draw.io file with 9 pages (tabs) for the GCP Landing Zone.

Design system (Google Cloud style):
  - Canvas: white, generous whitespace
  - Palette: official Google brand colors (Blue/Red/Yellow/Green/Purple/Grey)
  - Cards: white fill, 2px colored border, soft shadow, rounded corners
  - Typography (HTML labels):
        Page title  -> 22px bold  #202124
        Subtitle    -> 13px        #5F6368
        Group label -> 15px bold   accent color
        Card title  -> 14px bold   accent color (with icon)
        Card detail -> 11px        #5F6368
  - Edges: orthogonal rounded, semantic colors, white-bg labels

Run:    python _generate_v2.py
Output: landing-zone-architecture.drawio  (open in https://app.diagrams.net)
"""

import os
import re

# ----------------------------------------------------------------- palette --
# (stroke, titleColor, tintFill)
PAL = {
    "blue":   ("#4285F4", "#1967D2", "#E8F0FE"),
    "dblue":  ("#1A73E8", "#174EA6", "#D2E3FC"),
    "green":  ("#34A853", "#188038", "#E6F4EA"),
    "red":    ("#EA4335", "#C5221F", "#FCE8E6"),
    "yellow": ("#F9AB00", "#B06000", "#FEF7E0"),
    "purple": ("#A142F4", "#7627BB", "#F3E8FD"),
    "grey":   ("#9AA0A6", "#5F6368", "#F1F3F4"),
    "teal":   ("#12B5CB", "#0B7E8C", "#E4F7FA"),
}
TEXT = "#5F6368"   # subtitle grey
DET  = "#3C4043"   # body / detail text (dark grey)
INK  = "#202124"   # near-black headings
SKETCH = "sketch=1;curveFitting=1;jiggle=2;"   # hand-drawn aesthetic


def esc(s):
    return (s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
             .replace('"', "&quot;"))


def label_html(title, details, tcolor, title_px=20, detail_px=18, align="left"):
    """Build a RAW HTML label: bold near-black title + dark detail lines.
    The full string is XML-escaped later when written into the cell value."""
    s = (f'<b style="font-size:{title_px}px;color:{INK};'
         f'font-family:Helvetica;font-weight:800;line-height:1.35">{title}</b>')
    if details:
        body = "<br/>".join(details)
        s += (f'<div style="font-size:{detail_px}px;color:{DET};'
              f'font-family:Helvetica;line-height:1.5;margin-top:6px">{body}</div>')
    return s


class Page:
    # design canvas (A4 space) -> rendered on A3 via scale factor F
    def __init__(self, name, w=1169, h=826):
        self.name = name
        self.slug = re.sub(r"[^A-Za-z0-9]+", "_", name).strip("_")
        self.w, self.h = w, h            # design space (A4-ish)
        self.F = 1.357                   # element size scale (A4 -> A3)
        self.S = 2.2                     # spread factor (gaps between parts)
        self.nodes = []                  # top-level vertices (design coords)
        self.children = []               # child vertices (local design coords)
        self.edges = []                  # raw edge xml
        self.title_id = None
        self.PW = self.PH = 0
        self._id = 0

    def nid(self):
        self._id += 1
        return f"{self.slug}_n{self._id}"

    # --- top-level vertex (stored in design coords, transformed at emit) -
    def _vertex(self, value, style, x, y, w, h, nid=None, is_title=False,
                is_group=False):
        nid = nid or self.nid()
        self.nodes.append(dict(id=nid, value=value, style=style,
                               x=x, y=y, w=w, h=h, is_title=is_title,
                               is_group=is_group))
        if is_title:
            self.title_id = nid
        return nid

    # --- child vertex (local coords relative to parent; size-only scaled) -
    def _child(self, parent, value, style, lx, ly, lw, lh):
        nid = self.nid()
        self.children.append(dict(id=nid, parent=parent, value=value,
                                  style=style, x=lx, y=ly, w=lw, h=lh))
        return nid

    # --- auto icon (reliable built-in sketch shapes) --------------------
    @staticmethod
    def _pick_icon(title):
        t = (title or "").lower()
        if any(k in t for k in ("admin", "user", "team", "human",
                                 "stakeholder", " ci", "/ ci")):
            return "actor"
        if any(k in t for k in ("vpc", "internet", "network", "subnet")):
            return "cloud"
        if any(k in t for k in ("bucket", "store", "state", "archive", "rds",
                                 "dynamo", "gcs", "database", "billing")):
            return "cylinder3"
        return "hexagon"

    def _icon(self, parent, kind, title, lx, ly, sz, white=False):
        stroke, _, tint = PAL[kind]
        shape = self._pick_icon(title)
        if white:
            st = (f"{SKETCH}html=1;shape={shape};fillColor=#FFFFFF;fillStyle=solid;"
                  f"strokeColor=#FFFFFF;strokeWidth=2.5;")
        else:
            st = (f"{SKETCH}html=1;shape={shape};fillColor={tint};fillStyle=solid;"
                  f"strokeColor={stroke};strokeWidth=2.5;")
        self._child(parent, "", st, lx, ly, sz, sz)
        return shape

    # --- page title (centered over the content) -------------------------
    def title(self, big, small, x=28, y=14):
        v = (f'<div style="text-align:center">'
             f'<span style="font-size:32px;color:{INK};font-family:Helvetica;'
             f'font-weight:800">{big}</span>'
             f'<div style="font-size:23px;color:{DET};font-family:Helvetica;'
             f'font-weight:600;margin-top:10px">{small}</div></div>')
        st = ("text;html=1;strokeColor=none;fillColor=none;align=center;"
              "verticalAlign=middle;whiteSpace=wrap;")
        return self._vertex(v, st, x, y, self.w - 56, 88, is_title=True)

    # --- card ------------------------------------------------------------
    def card(self, kind, title, details, x, y, w, h, title_px=20, detail_px=18,
             align="left"):
        stroke, tcolor, _ = PAL[kind]
        sz = min(40, h - 14)
        pad = round((9 + sz) * self.F + 14)
        st = (f"{SKETCH}rounded=1;whiteSpace=wrap;html=1;fillColor=#FFFFFF;"
              f"strokeColor={stroke};strokeWidth=2.5;shadow=1;arcSize=8;"
              f"fontFamily=Helvetica;verticalAlign=middle;align={align};"
              f"spacingLeft={pad};spacingRight=12;spacingTop=6;spacingBottom=6;")
        nid = self._vertex(label_html(title, details, tcolor, title_px, detail_px),
                           st, x, y, w, h)
        self._icon(nid, kind, title, 9, (h - sz) / 2, sz)
        return nid

    # --- emphasized solid card (hero/banner nodes) -----------------------
    def solid(self, kind, title, details, x, y, w, h, title_px=20):
        stroke, _, _ = PAL[kind]
        fill = stroke
        sz = min(38, h - 12)
        pad = round((9 + sz) * self.F + 14)
        v = (f'<b style="font-size:{title_px}px;color:#FFFFFF;'
             f'font-family:Helvetica;font-weight:800;line-height:1.35">{title}</b>')
        if details:
            body = "<br/>".join(details)
            v += (f'<div style="font-size:16px;color:#F1F3F4;'
                  f'font-family:Helvetica;line-height:1.5;margin-top:4px">{body}</div>')
        st = (f"{SKETCH}rounded=1;whiteSpace=wrap;html=1;fillColor={fill};"
              f"fillStyle=solid;strokeColor={fill};strokeWidth=1.5;shadow=1;arcSize=10;"
              f"fontFamily=Helvetica;verticalAlign=middle;align=left;"
              f"spacingLeft={pad};spacingRight=12;")
        nid = self._vertex(v, st, x, y, w, h)
        self._icon(nid, kind, title, 9, (h - sz) / 2, sz, white=True)
        return nid

    # --- group / container ----------------------------------------------
    def group(self, kind, label, x, y, w, h, dashed=False):
        stroke, tcolor, tint = PAL[kind]
        d = "dashed=1;dashPattern=8 5;" if dashed else "dashed=0;"
        gpad = round((14 + 30) * self.F + 12)
        v = (f'<b style="font-size:22px;color:{tcolor};font-family:Helvetica;'
             f'font-weight:800">{label}</b>')
        st = (f"{SKETCH}rounded=1;whiteSpace=wrap;html=1;fillColor={tint};"
              f"strokeColor={stroke};strokeWidth=2.5;arcSize=3;fontFamily=Helvetica;"
              f"verticalAlign=top;align=left;spacingLeft={gpad};spacingTop=16;"
              f"{d}opacity=60;")
        nid = self._vertex(v, st, x, y, w, h, is_group=True)
        self._icon(nid, kind, label, 14, 10, 30)
        return nid

    # --- note sticky -----------------------------------------------------
    def note(self, kind, title, details, x, y, w, h):
        stroke, tcolor, tint = PAL[kind]
        sz = min(36, h - 14)
        pad = round((9 + sz) * self.F + 12)
        st = (f"{SKETCH}rounded=1;whiteSpace=wrap;html=1;fillColor={tint};"
              f"strokeColor={stroke};strokeWidth=2;arcSize=10;shadow=0;"
              f"fontFamily=Helvetica;verticalAlign=middle;align=left;"
              f"dashed=1;dashPattern=8 5;spacingLeft={pad};spacingRight=12;")
        nid = self._vertex(label_html(title, details, tcolor, 19, 17),
                           st, x, y, w, h)
        self._icon(nid, kind, title, 9, (h - sz) / 2, sz)
        return nid

    # --- edge ------------------------------------------------------------
    def edge(self, src, dst, label="", color="#9AA0A6", dashed=False,
             bidir=False, thick=False, exit=None, entry=None, rounded=True):
        st = (f"{SKETCH}edgeStyle=orthogonalEdgeStyle;rounded={1 if rounded else 0};"
              f"html=1;jettySize=auto;orthogonalLoop=1;strokeColor={color};"
              f"strokeWidth={4 if thick else 2.5};fontColor={INK};"
              f"fontFamily=Helvetica;fontSize=15;fontStyle=1;endArrow=block;endFill=1;"
              f"labelBackgroundColor=#FFFFFF;spacingTop=2;")
        if dashed:
            st += "dashed=1;dashPattern=8 5;"
        if bidir:
            st += "startArrow=block;startFill=1;"
        if exit:
            st += f"exitX={exit[0]};exitY={exit[1]};exitDx=0;exitDy=0;"
        if entry:
            st += f"entryX={entry[0]};entryY={entry[1]};entryDx=0;entryDy=0;"
        eid = self.nid()
        val = esc(f'<span style="font-family:Helvetica;font-size:15px;'
                  f'font-weight:700;color:{INK}">{label}</span>') if label else ""
        self.edges.append(
            f'<mxCell id="{eid}" value="{val}" style="{st}" edge="1" parent="1" '
            f'source="{src}" target="{dst}"><mxGeometry relative="1" '
            f'as="geometry"/></mxCell>'
        )
        return eid

    def xml(self):
        F, S = self.F, self.S
        cx0, cy0 = self.w / 2.0, self.h / 2.0
        nodes = [n for n in self.nodes if not n["is_title"]]
        groups = [n for n in nodes if n.get("is_group")]
        leaves = [n for n in nodes if not n.get("is_group")]

        def contains(a, b):
            return (a["x"] <= b["x"] and a["y"] <= b["y"]
                    and a["x"] + a["w"] >= b["x"] + b["w"]
                    and a["y"] + a["h"] >= b["y"] + b["h"]
                    and a["id"] != b["id"])

        placed = {}

        # 1) spread every LEAF component apart about the page center
        def spread(n):
            ecx = n["x"] + n["w"] / 2.0
            ecy = n["y"] + n["h"] / 2.0
            ncx = cx0 + (ecx - cx0) * S
            ncy = cy0 + (ecy - cy0) * S
            fw, fh = n["w"] * F, n["h"] * F
            return [ncx * F - fw / 2.0, ncy * F - fh / 2.0, fw, fh]

        for l in leaves:
            placed[l["id"]] = spread(l)

        # 2) grow each GROUP (innermost first) to wrap its spread children
        GPAD = 34.0      # side/bottom padding (rendered px)
        LPAD = 58.0      # extra top padding for the group label
        for g in sorted(groups, key=lambda g: g["w"] * g["h"]):
            kids = [placed[n["id"]] for n in nodes
                    if n["id"] != g["id"] and n["id"] in placed
                    and contains(g, n)]
            if kids:
                kminx = min(k[0] for k in kids)
                kminy = min(k[1] for k in kids)
                kmaxx = max(k[0] + k[2] for k in kids)
                kmaxy = max(k[1] + k[3] for k in kids)
                placed[g["id"]] = [kminx - GPAD, kminy - LPAD,
                                   (kmaxx - kminx) + 2 * GPAD,
                                   (kmaxy - kminy) + GPAD + LPAD]
            else:
                placed[g["id"]] = spread(g)

        xs = [v[0] for v in placed.values()]
        ys = [v[1] for v in placed.values()]
        xe = [v[0] + v[2] for v in placed.values()]
        ye = [v[1] + v[3] for v in placed.values()]
        minx, miny = min(xs), min(ys)
        maxx, maxy = max(xe), max(ye)
        # layout band: centered title above content, generous margins
        mX, mTop, mBot = 80, 56, 80
        titleH, gapT = 132, 48
        dx = mX - minx
        dy = mTop + titleH + gapT - miny
        for k in placed:
            placed[k][0] += dx
            placed[k][1] += dy
        contentW = maxx - minx
        contentH = maxy - miny
        self.PW = int(round(contentW + 2 * mX))
        self.PH = int(round(titleH + gapT + contentH + mTop + mBot))
        # title geometry: centered over full content width
        tgeo = (mX, mTop, contentW, titleH)

        cells = []
        for n in self.nodes:
            if n["is_title"]:
                gx, gy, gw, gh = tgeo
            else:
                gx, gy, gw, gh = placed[n["id"]]
            cells.append(
                f'<mxCell id="{n["id"]}" value="{esc(n["value"])}" '
                f'style="{n["style"]}" vertex="1" parent="1">'
                f'<mxGeometry x="{round(gx)}" y="{round(gy)}" '
                f'width="{round(gw)}" height="{round(gh)}" as="geometry"/></mxCell>'
            )
        # child icons: local coords relative to parent, size-only scaled
        for c in self.children:
            cells.append(
                f'<mxCell id="{c["id"]}" value="{esc(c["value"])}" '
                f'style="{c["style"]}" vertex="1" parent="{c["parent"]}">'
                f'<mxGeometry x="{round(c["x"] * F)}" y="{round(c["y"] * F)}" '
                f'width="{round(c["w"] * F)}" height="{round(c["h"] * F)}" '
                f'as="geometry"/></mxCell>'
            )
        cells.extend(self.edges)
        body = "\n        ".join(cells)
        return (
            f'  <diagram name="{esc(self.name)}" id="{self.slug}">\n'
            f'    <mxGraphModel dx="1422" dy="820" grid="0" gridSize="10" '
            f'guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" '
            f'pageScale="1" pageWidth="{self.PW}" pageHeight="{self.PH}" math="0" '
            f'shadow="0" background="#FFFFFF">\n'
            "      <root>\n"
            '        <mxCell id="0"/>\n'
            '        <mxCell id="1" parent="0"/>\n'
            f"        {body}\n"
            "      </root>\n"
            "    </mxGraphModel>\n"
            "  </diagram>\n"
        )


# =====================================================================  P1  ==
def p1():
    p = Page("1 - Overview")
    p.title("Enterprise GCP Landing Zone - System Overview",
            "Hub-and-Spoke - Shared VPC - Zero External IP - Centralized Observability - 100% Terraform on asia-southeast1")
    org = p.solid("dblue", "Organization (GCP Org Root)",
                  ["7 Org Policy guardrails - asia-southeast1"], 360, 70, 320, 88)
    sbx = p.group("grey", "Folder: sandbox (reserved - empty)", 780, 78, 290, 78)
    plat = p.group("blue", "Folder: platform - Shared infra (Network & SRE)", 24, 232, 660, 512)
    conn = p.group("blue", "Sub-folder: connectivity", 48, 296, 300, 424, dashed=True)
    mgf = p.group("yellow", "Sub-folder: management", 372, 296, 290, 424, dashed=True)
    hub = p.card("blue", "hub-net - lz-prj-hub-net",
                 ["Hub VPC 10.0.0.0/24 - GLOBAL",
                  "HA VPN - Cloud Router ASN 65003 - BGP",
                  "Private Google Access - flow logs 0.5"], 64, 356, 268, 158)
    shv = p.card("green", "sh-vpc - lz-prj-sh-vpc",
                 ["Shared VPC Host 10.20.1.0/24",
                  "Cloud NAT (egress) - Cloud DNS private",
                  "flow logs 0.1 - Host mode ON"], 64, 548, 268, 158)
    mgmt = p.card("yellow", "management",
                  ["Log Sinks (org+folder) - Hot 90d",
                   "GCS Archive 365d - Log Views",
                   "3 Alerts - 2 Dashboards - Budget"], 388, 356, 258, 168)
    sec = p.card("red", "security",
                 ["Hierarchical Org Firewall Policy",
                  "Admin IAM - IAP & Log-View access"], 388, 560, 258, 134)
    work = p.group("green", "Folder: workload - App team", 770, 232, 320, 280)
    app = p.card("green", "sample-app",
                 ["Service Project (Shared VPC)",
                  "VM e2-small + Ops Agent",
                  "No public IP - Shielded VM"], 790, 296, 284, 190)
    adm = p.card("red", "Cloud Admin",
                 ["gcloud ssh --tunnel-through-iap"], 770, 568, 320, 96)
    onp = p.card("grey", "On-Premises Data Center",
                 ["RFC1918 - peer ASN 65002"], 24, 788, 300, 96)
    net = p.card("grey", "Internet", None, 430, 800, 220, 80)
    # hierarchy
    p.edge(org, plat, color="#1A73E8", exit=(0.3, 1), entry=(0.45, 0))
    p.edge(org, work, color="#1A73E8", exit=(0.7, 1), entry=(0.35, 0))
    p.edge(org, sbx, color="#9AA0A6", dashed=True, exit=(1, 0.5), entry=(0, 0.5))
    # networking
    p.edge(hub, shv, "VPC Peering (custom routes)", color="#4285F4", bidir=True,
           exit=(0.5, 1), entry=(0.5, 0))
    p.edge(shv, app, "Shared VPC attach", color="#34A853", dashed=True,
           exit=(1, 0.85), entry=(0, 0.8))
    p.edge(hub, onp, "HA VPN (eBGP)", color="#A142F4", bidir=True,
           exit=(0, 0.5), entry=(0.5, 0))
    p.edge(shv, net, "Cloud NAT (egress)", color="#34A853",
           exit=(0.35, 1), entry=(0.5, 0))
    p.edge(adm, app, "Cloud IAP - tcp 22/3389", color="#EA4335",
           exit=(0.5, 0), entry=(0.5, 1))
    # observability (single labelled edge to reduce clutter)
    p.edge(mgmt, hub, color="#9AA0A6", dashed=True, exit=(0, 0.3), entry=(1, 0.25))
    p.edge(mgmt, shv, color="#9AA0A6", dashed=True, exit=(0, 0.8), entry=(1, 0.25))
    p.edge(mgmt, app, "logs & metrics", color="#9AA0A6", dashed=True,
           exit=(1, 0.4), entry=(0, 0.4))
    return p


# =====================================================================  P2  ==
def p2():
    p = Page("2 - Resource Hierarchy")
    p.title("Resource Hierarchy & Billing Split",
            "Folder tree - Project Factory v17.1.0 - platform vs workload billing - globally-unique project IDs")
    root = p.solid("dblue", "Organization Root", None, 445, 92, 280, 48)
    plat = p.card("blue", "Folder: platform", ["Shared infra - Network & SRE"], 70, 178, 300, 66)
    wkf = p.card("green", "Folder: workload", ["Application - App team"], 430, 178, 300, 66)
    sbf = p.card("grey", "Folder: sandbox", ["Isolated - empty (reserved)"], 790, 178, 300, 66)
    mgf = p.card("yellow", "Sub-folder: management", ["Observability & Security"], 40, 300, 280, 64)
    cnf = p.card("blue", "Sub-folder: connectivity", ["Core Network Layer"], 360, 300, 280, 64)
    pm = p.card("yellow", "gcp-platform-management",
                ["random_project_id = true",
                 "logging - monitoring - bigquery",
                 "pubsub - storage - billingbudgets"], 40, 420, 300, 116)
    ps = p.card("yellow", "gcp-platform-security",
                ["random_project_id = true",
                 "cloudkms - secretmanager",
                 "securitycenter - pubsub - iam"], 40, 556, 300, 116)
    hn = p.card("blue", "lz-prj-hub-net-{suffix}",
                ["Hub VPC - HA VPN - Router - NAT",
                 "APIs: compute - dns - logging"], 360, 420, 300, 100)
    sv = p.card("blue", "lz-prj-sh-vpc-{suffix}",
                ["Shared VPC Host Project",
                 "APIs: compute - monitoring"], 360, 540, 300, 96)
    sa = p.card("green", "lz-prj-sample-app-{suffix}",
                ["Service Project (Shared VPC)",
                 "APIs: compute - logging - monitoring"], 760, 300, 300, 90)
    b1 = p.solid("yellow", "Billing #1 - Platform", ["billing_account_id_1"], 760, 410, 290, 54)
    b2 = p.solid("purple", "Billing #2 - Workload", ["billing_account_id_2"], 760, 478, 290, 54)
    nt = p.note("teal", "Globally-unique Project IDs",
                ["random 4-char suffix (random_string)",
                 "e.g. lz-prj-hub-net-a3f9",
                 "redeploy in parallel - no name clash"], 760, 548, 375, 130)
    p.edge(root, plat, color="#1A73E8"); p.edge(root, wkf, color="#1A73E8")
    p.edge(root, sbf, color="#9AA0A6", dashed=True)
    p.edge(plat, mgf, color="#4285F4"); p.edge(plat, cnf, color="#4285F4")
    p.edge(mgf, pm, color="#F9AB00"); p.edge(mgf, ps, color="#F9AB00")
    p.edge(cnf, hn, color="#4285F4"); p.edge(cnf, sv, color="#4285F4")
    p.edge(wkf, sa, color="#34A853")
    p.edge(b1, pm, color="#F9AB00", dashed=True)
    p.edge(b1, ps, color="#F9AB00", dashed=True)
    p.edge(b2, hn, color="#A142F4", dashed=True)
    p.edge(b2, sv, color="#A142F4", dashed=True)
    p.edge(b2, sa, color="#A142F4", dashed=True)
    return p


# =====================================================================  P3  ==
def p3():
    p = Page("3 - Five Stacks")
    p.title("Five Independent Stacks & Apply Order",
            "Separate GCS backend - separate Runner Service Account - separate state prefix -> isolated blast radius, parallel ops")
    a = p.card("purple", "1. org/",
               ["Folders (terraform-google/folders 5.1.0)",
                "Project Factory 17.1.0 -> 5 projects",
                "7 Org Policy guardrails"], 40, 320, 250, 120)
    b = p.card("purple", "2. connectivity/",
               ["2 GLOBAL VPCs - Shared VPC - Peering",
                "Cloud NAT - Cloud DNS - HA VPN+BGP"], 330, 180, 250, 110)
    c = p.card("purple", "3. security/",
               ["Hierarchical Org Firewall Policy",
                "Admin IAM - IAP - Log-View access"], 330, 470, 250, 110)
    d = p.card("purple", "4. workload/",
               ["VM e2-small + Ops Agent",
                "on Shared VPC - enable_sample_vm"], 620, 320, 250, 110)
    e = p.card("purple", "5. management/",
               ["Log Sinks - Buckets - Views",
                "Dashboards - 3 Alerts - Budget"], 900, 320, 240, 110)
    saa = p.card("green", "org-runner", ["state prefix -> org/"], 40, 170, 230, 64)
    sab = p.card("green", "connectivity-runner", ["prefix -> connectivity/"], 320, 92, 270, 64)
    sac = p.card("green", "security-runner", ["prefix -> security/"], 320, 620, 270, 64)
    sad = p.card("green", "workload-runner", ["prefix -> workload/"], 620, 170, 250, 64)
    sae = p.card("green", "management-runner", ["prefix -> management/"], 895, 170, 245, 64)
    why = p.note("teal", "Why 5 stacks?",
                 ["Isolate blast radius - parallel ops",
                  "Least-privilege - state isolation per prefix",
                  "GCS backend - object versioning - per-prefix IAM lock"],
                 880, 470, 260, 140)
    for s, t in [(a, b), (a, c), (a, d), (b, d), (b, e), (d, e)]:
        p.edge(s, t, color="#A142F4", thick=True)
    for s, n in [(saa, a), (sab, b), (sac, c), (sad, d), (sae, e)]:
        p.edge(s, n, "impersonate", color="#34A853", dashed=True)
    p.edge(d, why, color="#12B5CB", dashed=True)
    return p


# =====================================================================  P4  ==
def p4():
    p = Page("4 - Hub-Spoke IPAM")
    p.title("Hub-and-Spoke + IP Address Plan (IPAM)",
            "2 custom-mode GLOBAL VPCs - VPC Peering custom routes - Cloud Router advertises /20 -> add subnets without touching BGP")
    hubp = p.group("blue", "lz-prj-hub-net", 40, 110, 510, 250)
    hvpc = p.group("dblue", "Hub VPC - gcp-sg-vpc-hub-001 (GLOBAL)", 58, 164, 476, 180, dashed=True)
    hsn = p.card("green", "gcp-sg-snet-hub-001  10.0.0.0/24",
                 ["Flow Sampling 0.5 - 5s interval - metadata INCLUDE_ALL",
                  "Private Google Access ON - routing GLOBAL",
                  "HA VPN Gateway + Cloud Router ASN 65003 - transit only, NO compute"], 72, 210, 448, 124)
    shp = p.group("green", "lz-prj-sh-vpc", 40, 400, 510, 250)
    svpc = p.group("dblue", "Shared VPC - gcp-sg-vpc-shared-001 (GLOBAL - Host)", 58, 454, 476, 180, dashed=True)
    ssn = p.card("green", "gcp-sg-snet-app-001  10.20.1.0/24",
                 ["Flow Sampling 0.1 - 5s interval",
                  "Private Google Access ON",
                  "Workload VMs + Cloud NAT egress"], 72, 500, 448, 124)
    ipam = p.note("teal", "IP Plan (IPAM)",
                  ["snet-hub-001 -> 10.0.0.0/24   (Hub - sampling 0.5)",
                   "snet-app-001 -> 10.20.1.0/24  (Shared - sampling 0.1)",
                   "reserved     -> 10.20.0.0/20  (16x /24 future subnets)",
                   "BGP link-local -> 169.254.0.0/16"], 590, 120, 550, 158)
    routing = p.note("blue", "Peering & Routing",
                     ["export & import CUSTOM routes - NON-TRANSITIVE",
                      "routing_mode = GLOBAL on both VPCs"], 590, 300, 550, 110)
    adv = p.note("yellow", "Cloud Router advertisement",
                 ["advertise_mode = CUSTOM - ALL_SUBNETS",
                  "+ advertised range 10.20.0.0/20 (4096 IPs)",
                  "-> add subnets WITHOUT touching BGP"], 590, 432, 550, 120)
    p.edge(hvpc, svpc, "VPC Peering - NON-TRANSITIVE - custom routes", color="#4285F4", bidir=True, thick=True)
    p.edge(ssn, adv, color="#F9AB00", dashed=True)
    return p


# =====================================================================  P5  ==
def p5():
    p = Page("5 - HA VPN + BGP")
    p.title("HA VPN + BGP - Hybrid to On-Premises (dynamic routing)",
            "2 redundant tunnels - eBGP 65003 <-> 65002 - auto-converge on tunnel failure - OPTIONAL (disabled by default)")
    gcp = p.group("blue", "GCP - Hub VPC - lz-prj-hub-net", 40, 120, 470, 320)
    router = p.card("blue", "Cloud Router - gcp-sg-router-hub-001",
                    ["ASN 65003 - advertise CUSTOM",
                     "ALL_SUBNETS + 10.20.0.0/20",
                     "advertised_route_priority = 100"], 70, 176, 410, 116)
    gw = p.card("blue", "HA VPN Gateway - gcp-sg-vpn-hub-001",
                ["2 interfaces (iface0 - iface1)",
                 "IKEv2 / IPsec"], 70, 314, 410, 100)
    onp = p.group("green", "On-Premises Datacenter", 660, 150, 480, 290)
    peer = p.card("green", "External VPN Gateway",
                  ["gcp-sg-vpn-external-peer-001",
                   "TWO_IPS_REDUNDANCY - ASN 65002",
                   "two public IPs"], 690, 210, 420, 150)
    warn = p.note("red", "VPN is OPTIONAL - disabled by default (vpn_enabled=0)",
                  ["Created only when on-prem public IPs",
                   "+ 2 shared secrets are set in tfvars"], 40, 540, 360, 110)
    bgp = p.note("purple", "eBGP 65003 (GCP) <-> 65002 (on-prem)",
                 ["If one tunnel fails -> BGP auto-converges",
                  "traffic shifts to surviving tunnel"], 430, 540, 330, 110)
    specs = p.note("teal", "Tunnel specs",
                   ["Tunnel 0: iface0<->peer0",
                    "  BGP 169.254.0.1/30 <-> .2 - PSK #1",
                    "Tunnel 1: iface1<->peer1",
                    "  BGP 169.254.1.1/30 <-> .2 - PSK #2"], 790, 470, 350, 175)
    p.edge(router, gw, "attach", color="#4285F4")
    p.edge(gw, peer, "Tunnel 0 - BGP 169.254.0.1/30 - PSK #1", color="#A142F4", thick=True)
    p.edge(gw, peer, "Tunnel 1 - BGP 169.254.1.1/30 - PSK #2", color="#A142F4", thick=True)
    p.edge(peer, bgp, color="#A142F4", dashed=True)
    p.edge(gcp, warn, color="#EA4335", dashed=True)
    return p


# =====================================================================  P6  ==
def p6():
    p = Page("6 - Firewall Two-Tier")
    p.title("Two-Tier Firewall - Defense in Depth",
            "Tier 1 Hierarchical Policy (Org, evaluated FIRST) -> delegate RFC1918 -> Tier 2 VPC rules -> implicit DENY")
    inp = p.solid("dblue", "Ingress Packet", None, 460, 96, 240, 48)
    t1 = p.group("grey", "TIER 1 - Hierarchical Firewall Policy (Org level - evaluated FIRST)",
                 30, 160, 760, 272)
    r1000 = p.card("yellow", "p.1000 / 1001 - goto_next",
                   ["Delegate RFC1918 ingress/egress",
                    "10.0.0.0/8 - 172.16/12 - 192.168/16"], 55, 214, 350, 92)
    r1002 = p.card("green", "p.1002 - ALLOW IAP SSH/RDP",
                   ["35.235.240.0/20 -> tcp 22, 3389"], 420, 214, 350, 80)
    r1004 = p.card("green", "p.1004 - ALLOW Google Load Balancer / Health Check",
                   ["35.191/16 - 130.211/22 -> tcp 80,443"], 55, 322, 350, 84)
    r1005 = p.card("red", "p.1005 - DENY TOR exit nodes",
                   ["src_threat_intelligences = iplist-tor-exit-nodes"], 420, 322, 350, 84)
    t2 = p.group("grey", "TIER 2 - VPC Firewall Rules (per-VPC - after Tier 1 delegates)",
                 30, 462, 760, 248)
    f1 = p.card("green", "gcp-sg-fw-allow-vpn-hub-001",
                ["on-prem CIDRs -> Hub VPC (tcp/udp/icmp)",
                 "CONDITIONAL (only if onprem CIDRs set)"], 55, 516, 350, 86)
    f2 = p.card("green", "gcp-sg-fw-allow-internal-001",
                ["10.20.0.0/20 -> Shared VPC",
                 "tcp/udp/icmp/ipip"], 420, 516, 350, 86)
    f3 = p.card("red", "Everything else -> Implicit DENY", None, 55, 624, 715, 56)
    aok = p.solid("green", "ALLOW", None, 860, 300, 200, 54)
    dno = p.solid("red", "DENY", None, 860, 470, 200, 54)
    nt = p.note("teal", "Cloud IAP = the ONLY admin door",
                ["IAM + OS Login verified before packet reaches VM",
                 "Lower priority number = higher precedence"], 830, 560, 310, 120)
    for r in (r1000, r1002, r1004, r1005):
        p.edge(inp, r, color="#1A73E8")
    p.edge(r1000, t2, "goto_next", color="#F9AB00", thick=True)
    p.edge(r1002, aok, color="#34A853"); p.edge(r1004, aok, color="#34A853")
    p.edge(r1005, dno, color="#EA4335")
    p.edge(f1, aok, color="#34A853"); p.edge(f2, aok, color="#34A853")
    p.edge(f3, dno, color="#EA4335")
    p.edge(t2, nt, color="#12B5CB", dashed=True)
    return p


# =====================================================================  P7  ==
def p7():
    p = Page("7 - Zero External IP")
    p.title("Zero External IP - Egress via NAT, Ingress via IAP",
            "Org Policy denies all public IPs - admin enters via Cloud IAP tunnel - VM reaches Internet one-way via Cloud NAT")
    adm = p.card("red", "Cloud Admin",
                 ["gcloud compute ssh", "--tunnel-through-iap"], 40, 250, 280, 92)
    iap = p.card("purple", "Cloud IAP - 35.235.240.0/20",
                 ["authenticate IAM + OS Login", "iap.tunnelResourceAccessor"], 400, 244, 300, 104)
    svpc = p.group("blue", "Shared VPC - gcp-sg-vpc-shared-001", 780, 150, 360, 270)
    sn = p.group("green", "gcp-sg-snet-app-001 - 10.20.1.0/24", 805, 205, 320, 190, dashed=True)
    vm = p.card("green", "VM e2-small + Ops Agent",
                ["internal IP 10.20.1.x - NO public IP",
                 "debian-12 - pd-balanced 20GB",
                 "Shielded VM - OS Login - tag app-vm"], 825, 252, 280, 122)
    nat = p.card("green", "Cloud NAT - gcp-sg-nat-001",
                 ["AUTO_ONLY - LIST_OF_SUBNETWORKS", "log ERRORS_ONLY"], 780, 460, 360, 92)
    net = p.card("grey", "Internet", None, 950, 600, 190, 60)
    guard = p.note("red", "Org Policy: compute.vmExternalIpAccess = deny_all",
                   ["No VM can ever have a public IP",
                    "Internet CANNOT initiate inbound"], 40, 460, 470, 92)
    specs = p.note("teal", "VM specs",
                   ["machine_type e2-small - zone asia-southeast1-b",
                    "deletion_protection ON - automatic_restart ON",
                    "enable_sample_vm toggles creation"], 40, 600, 470, 120)
    p.edge(adm, iap, "TLS - IAM auth", color="#A142F4")
    p.edge(iap, vm, "tunnel to 10.20.1.x", color="#A142F4")
    p.edge(vm, nat, "egress only", color="#34A853")
    p.edge(nat, net, "one-way source NAT", color="#34A853")
    p.edge(vm, guard, color="#EA4335", dashed=True)
    return p


# =====================================================================  P8  ==
def p8():
    p = Page("8 - Shared VPC SoD")
    p.title("Shared VPC - Host vs Service (Separation of Duties)",
            "Network/SRE owns the network in the Host project - App team only deploys workloads in the Service project")
    t1 = p.solid("yellow", "Network / SRE Team", ["owns & controls the network"], 80, 100, 300, 60)
    t2 = p.solid("yellow", "Application Team", ["deploys workloads only"], 800, 100, 300, 60)
    host = p.group("blue", "Host Project - lz-prj-sh-vpc (Host mode ON)", 70, 210, 480, 340)
    vpc = p.card("blue", "VPC gcp-sg-vpc-shared-001",
                 ["subnet gcp-sg-snet-app-001",
                  "10.20.1.0/24 - GLOBAL routing",
                  "google_compute_shared_vpc_host_project"], 100, 268, 420, 100)
    extra = p.card("blue", "Network controls",
                   ["Firewall Rules - Routes",
                    "Cloud NAT - Cloud DNS private",
                    "binds role compute.networkUser"], 100, 400, 420, 110)
    svc = p.group("green", "Service Project - lz-prj-sample-app", 720, 210, 420, 230)
    vm = p.card("green", "VM e2-small",
                ["deploys apps - consumes shared subnet",
                 "subnetwork_project = host",
                 "shared_vpc_service_project link"], 750, 268, 360, 120)
    iam = p.note("teal", "Separation of Duties",
                 ["App team uses the network WITHOUT touching",
                  "subnets - firewall - routing - VPN",
                  "compute.networkUser granted at subnet scope"], 70, 580, 480, 130)
    nt = p.note("blue", "Wiring resources",
                ["shared_vpc_host_project (enables Host)",
                 "shared_vpc_service_project (attaches Service)"], 720, 470, 420, 110)
    p.edge(vpc, extra, color="#4285F4")
    p.edge(t1, host, color="#F9AB00", dashed=True)
    p.edge(t2, svc, color="#F9AB00", dashed=True)
    p.edge(host, svc, "Shared VPC attachment", color="#4285F4", thick=True)
    p.edge(svc, nt, color="#12B5CB", dashed=True)
    return p


# =====================================================================  P9  ==
def p9():
    p = Page("9 - Impersonation & Observability")
    p.title("Zero-Key Impersonation + Centralized Observability",
            "No static Service Account keys - each Service Account writes only its state prefix - logs/metrics centralized to Management - Budget alerts")
    left = p.group("blue", "Zero-Key Impersonation (no static Service Account keys)", 28, 150, 540, 600)
    adm = p.solid("dblue", "Human Admin / CI", None, 168, 188, 260, 46)
    s1 = p.card("green", "org-runner", None, 45, 272, 160, 46, title_px=13)
    s2 = p.card("green", "connectivity-runner", None, 215, 272, 175, 46, title_px=13)
    s3 = p.card("green", "security-runner", None, 400, 272, 150, 46, title_px=13)
    s4 = p.card("green", "workload-runner", None, 130, 344, 170, 46, title_px=13)
    s5 = p.card("green", "management-runner", None, 320, 344, 175, 46, title_px=13)
    st = p.card("blue", "GCS Terraform State",
                ["each Service Account writes ONLY its prefix",
                 "per-prefix IAM lock - Object Versioning"], 70, 432, 460, 86)
    pol = p.note("red", "Org Policy: iam.disableServiceAccountKeyCreation",
                 ["static Service Account keys forbidden org-wide"], 70, 560, 460, 80)
    right = p.group("green", "Centralized Observability & Cost Control", 600, 150, 540, 600)
    pp1 = p.card("blue", "hub-net", None, 625, 192, 150, 46, title_px=13)
    pp2 = p.card("blue", "sh-vpc", None, 790, 192, 150, 46, title_px=13)
    pp3 = p.card("green", "sample-app", None, 955, 192, 160, 46, title_px=13)
    mg = p.solid("yellow", "management project", ["the single Metrics Scope"], 760, 268, 300, 54)
    hot = p.card("green", "Log Bucket - HOT tier",
                 ["retention 90 days",
                  "org + folder sinks"], 620, 358, 250, 86)
    views = p.card("blue", "Log Views (scoped read)",
                   ["sample-app - hub-net",
                    "SOURCE(...) per project"], 890, 358, 240, 86)
    cold = p.card("teal", "GCS Archive - COLD tier",
                  ["retention 365 days - ARCHIVE",
                   "versioning ON"], 620, 466, 250, 86)
    mon = p.card("blue", "Cloud Monitoring",
                 ["3 Alerts: CPU/MEM/DISK",
                  "2 Dashboards - email channel"], 890, 466, 240, 86)
    bud = p.solid("yellow", "Billing Budget",
                  ["2,500,000 VND/mo - alert 50/80/100% + forecast"], 700, 590, 360, 54)
    for s in (s1, s2, s3, s4, s5):
        lbl = "impersonate - short-lived token" if s == s1 else ""
        p.edge(adm, s, lbl, color="#1A73E8")
        p.edge(s, st, color="#34A853")
    p.edge(st, pol, color="#EA4335", dashed=True)
    p.edge(pp1, mg, "Log Sinks", color="#34A853")
    p.edge(pp2, mg, color="#34A853"); p.edge(pp3, mg, color="#34A853")
    p.edge(mg, hot, color="#34A853"); p.edge(hot, cold, "tiering", color="#12B5CB")
    p.edge(mg, views, color="#4285F4"); p.edge(mg, mon, color="#4285F4")
    p.edge(mg, bud, color="#F9AB00")
    return p


def main():
    pages = [p1(), p2(), p3(), p4(), p5(), p6(), p7(), p8(), p9()]
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "landing-zone-architecture.drawio")
    parts = ['<mxfile host="app.diagrams.net" type="device" '
             'agent="landing-zone-generator">']
    parts += [pg.xml() for pg in pages]
    parts.append("</mxfile>\n")
    with open(out, "w", encoding="utf-8") as f:
        f.write("\n".join(parts))
    print("wrote", out, "with", len(pages), "tabs")


if __name__ == "__main__":
    main()
