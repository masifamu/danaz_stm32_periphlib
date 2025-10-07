import sys
import hashlib

def parse_makefile(filename):
    with open(filename) as f:
        data = f.read().replace("\\\n", " ")
    deps = {}
    for line in data.split("\n"):
        if ":" in line:
            target, sources = line.split(":", 1)
            if target.endswith(".o"):
                target = target.replace(".o", ".c")
            target = target.strip()
            deps_list = [s.strip() for s in sources.strip().split()]
            # Keep only .h files (skip self and .c deps)
            deps_list = [s for s in deps_list if s.endswith(".h")]
            if deps_list:
                deps[target] = deps_list
    return deps


# def color_from_string(s):
#     # Create a color code from the string hash
#     h = hashlib.md5(s.encode()).hexdigest()
#     r = int(h[0:2], 16)
#     g = int(h[2:4], 16)
#     b = int(h[4:6], 16)
#     return f"#{r:02x}{g:02x}{b:02x}"

# def to_dot(deps):
#     print("digraph Dependencies {")
#     print("    rankdir=LR;")
#     print("    graph [splines=true, nodesep=0.5, ranksep=10.0];")
#     print("    node [fontname=\"Arial\", fontsize=10, shape=box, style=filled];")
#     print("    edge [arrowsize=0.7, penwidth=1.2];")

#     for src, deps_list in deps.items():
#         if not src.endswith(".c"):
#             continue

#         edge_color = color_from_string(src)
#         print(f'    "{src}" [fillcolor=lightblue];')

#         for dep in deps_list:
#             print(f'    "{dep}" [shape=ellipse, fillcolor=lightyellow];')
#             print(f'    "{src}" -> "{dep}" [color="{edge_color}"];')
#     print("}")
import hashlib

def color_from_string(s):
    h = hashlib.md5(s.encode()).hexdigest()
    r = int(h[0:2], 16)
    g = int(h[2:4], 16)
    b = int(h[4:6], 16)
    return f"#{r:02x}{g:02x}{b:02x}"

def to_dot(deps):
    print("digraph Dependencies {")
    print("    rankdir=LR;")  # Left to right layout
    print("    graph [")
    print("        bgcolor=white,")
    print("        nodesep=0.5,")    # More horizontal spacing
    print("        ranksep=10.0,")    # More vertical spacing (affects horizontal in LR)
    print("        splines=true,") # Smooth edge curves
    print("        fontname=\"Helvetica\"")
    print("    ];")
    print("    node [")
    print("        shape=box,")
    print("        style=\"filled,rounded\",")
    print("        fontname=\"Helvetica\",")
    print("        fontsize=10,")
    print("        penwidth=1.0")
    print("    ];")
    print("    edge [")
    print("        fontname=\"Helvetica\",")
    print("        color=gray50,")
    print("        arrowsize=0.7,")
    print("        penwidth=1.5")
    print("    ];")

    for src, deps_list in deps.items():
        if not src.endswith(".c"):
            continue

        edge_color = color_from_string(src)
        print(f'    "{src}" [fillcolor=lightblue];')

        for dep in deps_list:
            print(f'    "{dep}" [shape=ellipse, fillcolor=lightgoldenrod1, style=filled];')
            print(f'    "{src}" -> "{dep}" [color="{edge_color}"];')
    print("}")



if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python deps_to_dot.py <deps.mk>")
        sys.exit(1)
    deps = parse_makefile(sys.argv[1])
    to_dot(deps)

