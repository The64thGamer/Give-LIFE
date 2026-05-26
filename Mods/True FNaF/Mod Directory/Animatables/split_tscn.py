#!/usr/bin/env python3
"""
Split a multi-model .tscn into one .tscn per animatronic.
Usage: python split_tscn.py Cutout.tscn [output_dir]
"""

import re
import sys
import os

TEMPLATE = """\
[gd_scene format=3 uid="{uid}"]

{ext_resource}
{sub_resource}
[node name="{name}" type="Node3D" unique_id=233530727 groups=["SOTM_CUTOUT"]]
script = ExtResource("1_bejbi")
animParametersFileName = "{name}"
animatableName = "Test"
animatableAuthors = "Steel Wool"
animatableColor = Color(0.84, 0.77783996, 0.52919996, 1)

[node name="{name}" parent="." unique_id={model_uid} instance=ExtResource("{model_res_id}")]
transform = {transform}

[node name="StaticBody3D" type="StaticBody3D" parent="." unique_id=723801955]

[node name="CollisionShape3D" type="CollisionShape3D" parent="StaticBody3D" unique_id=1095323835]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.657, 0)
shape = SubResource("BoxShape3D_um21q")
"""

# The script ext_resource is always the same
SCRIPT_EXT = '[ext_resource type="Script" uid="uid://iqrmm33dxvui" path="res://Scripts/Animatables/GL_Animatronic.gd" id="1_bejbi"]'

# The BoxShape3D sub_resource is always the same
BOX_SUB = '[sub_resource type="BoxShape3D" id="BoxShape3D_um21q"]'


def parse_ext_resources(text):
    """Return a dict of model name -> (uid, res_id, packed_scene_uid) from ext_resource lines."""
    # Match lines like:
    # [ext_resource type="PackedScene" uid="uid://..." path="res://.../Name.glb" id="N_xxxx"]
    pattern = re.compile(
        r'\[ext_resource type="PackedScene" uid="([^"]+)" path="[^"]+/([^"/]+)\.glb" id="([^"]+)"\]'
    )
    resources = {}
    for m in pattern.finditer(text):
        uid, name, res_id = m.group(1), m.group(2), m.group(3)
        resources[name] = {"uid": uid, "res_id": res_id}
    return resources


def parse_model_nodes(text):
    """Return dict of model name -> {unique_id, transform} from node blocks."""
    # Match node lines that instance a PackedScene (they come right after ext_resource defs)
    # e.g. [node name="Balloon Mice" parent="." unique_id=2097541763 instance=ExtResource("2_16vi6")]
    #       transform = Transform3D(...)
    pattern = re.compile(
        r'\[node name="([^"]+)" parent="\." unique_id=(\d+) instance=ExtResource\("([^"]+)"\)\]\s*\ntransform = (Transform3D\([^)]+\))',
        re.MULTILINE,
    )
    nodes = {}
    for m in pattern.finditer(text):
        name, uid, res_id, transform = m.group(1), m.group(2), m.group(3), m.group(4)
        nodes[name] = {"unique_id": uid, "res_id": res_id, "transform": transform}
    return nodes


def make_uid(name):
    """Generate a deterministic fake UID string based on the name (good enough for Godot imports)."""
    import hashlib
    h = hashlib.md5(name.encode()).hexdigest()[:12]
    return f"uid://{h}"


def main():
    if len(sys.argv) < 2:
        print("Usage: python split_tscn.py <input.tscn> [output_dir]")
        sys.exit(1)

    input_path = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else os.path.dirname(input_path) or "."
    os.makedirs(output_dir, exist_ok=True)

    with open(input_path, "r", encoding="utf-8") as f:
        text = f.read()

    resources = parse_ext_resources(text)
    nodes = parse_model_nodes(text)

    print(f"Found {len(resources)} PackedScene resources and {len(nodes)} model nodes.")

    for name, node_info in nodes.items():
        res_id = node_info["res_id"]
        # Find the matching ext_resource by res_id
        matching = {k: v for k, v in resources.items() if v["res_id"] == res_id}
        if not matching:
            print(f"  WARNING: no ext_resource found for node '{name}' (res_id={res_id}), skipping.")
            continue

        res_name, res_info = next(iter(matching.items()))

        # Build the ext_resource block for this model
        model_ext = (
            f'[ext_resource type="PackedScene" uid="{res_info["uid"]}" '
            f'path="res://Mods/True FNaF/Custom Assets/Models/Animatronics/{res_name}.glb" '
            f'id="{res_id}"]'
        )

        ext_block = SCRIPT_EXT + "\n" + model_ext

        content = TEMPLATE.format(
            uid=make_uid(name),
            ext_resource=ext_block,
            sub_resource=BOX_SUB,
            name=name,
            model_uid=node_info["unique_id"],
            model_res_id=res_id,
            transform=node_info["transform"],
        )

        out_file = os.path.join(output_dir, f"{name}.tscn")
        with open(out_file, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"  Written: {out_file}")

    print("Done.")


if __name__ == "__main__":
    main()
