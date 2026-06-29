#!/usr/bin/env python3
"""Genera VeriPhone.xcodeproj/project.pbxproj a partir del árbol de fuentes.

Formato clásico de Xcode (PBXFileReference/PBXBuildFile/PBXGroup), compatible
con Xcode 15/16. Se regenera de forma determinista a partir de los archivos
presentes en VeriPhone/, evitando errores manuales de UUID.
"""
import hashlib
import os
import uuid

ROOT = os.path.dirname(os.path.abspath(__file__))
SRC_ROOT = os.path.join(ROOT, "VeriPhone")
PROJECT_NAME = "VeriPhone"
ORG = "VeriPhone"
BUNDLE_ID = "com.veriphone.app"

def make_id(*parts):
    h = hashlib.md5("::".join(parts).encode("utf-8")).hexdigest()[:24].upper()
    return h

class Obj:
    def __init__(self, oid, isa, fields):
        self.oid = oid
        self.isa = isa
        self.fields = fields

objects = []

def add(isa, key, fields):
    oid = make_id(isa, key)
    objects.append(Obj(oid, isa, fields))
    return oid

# Walk source tree
swift_files = []
resource_files = []  # Assets.xcassets
plist_path = None

for dirpath, dirnames, filenames in os.walk(SRC_ROOT):
    dirnames.sort()
    for fname in sorted(filenames):
        full = os.path.join(dirpath, fname)
        rel = os.path.relpath(full, SRC_ROOT)
        if fname.endswith(".swift"):
            swift_files.append(rel)
        elif fname == "Info.plist":
            plist_path = rel
    if "Assets.xcassets" in dirnames:
        resource_files.append(os.path.relpath(os.path.join(dirpath, "Assets.xcassets"), SRC_ROOT))
        dirnames.remove("Assets.xcassets")  # don't descend; treated as single file ref

swift_files.sort()

# Build folder hierarchy of PBXGroup
group_cache = {}

def get_group(rel_dir):
    """rel_dir is '' for root or a path like 'Views/Diagnostic/Tests'."""
    if rel_dir in group_cache:
        return group_cache[rel_dir]
    if rel_dir == "":
        return None  # handled specially (main VeriPhone group)
    parent_dir = os.path.dirname(rel_dir)
    name = os.path.basename(rel_dir)
    parent_id = get_group(parent_dir) if parent_dir != "" else root_group_id
    gid = add("PBXGroup", "group:" + rel_dir, {
        "isa": "PBXGroup",
        "children": [],
        "sourceTree": "<group>",
        "name": name,
        "path": name,
    })
    group_cache[rel_dir] = gid
    # register into parent's children later
    pending_children.setdefault(parent_id, []).append(gid)
    return gid

pending_children = {}

# Root "VeriPhone" group (source root)
root_group_id = add("PBXGroup", "group:VeriPhone", {
    "isa": "PBXGroup",
    "children": [],
    "sourceTree": "<group>",
    "name": PROJECT_NAME,
    "path": PROJECT_NAME,
})

file_refs = {}     # rel path -> fileRef id
build_files = {}   # rel path -> buildFile id

for rel in swift_files:
    rel_dir = os.path.dirname(rel)
    fname = os.path.basename(rel)
    group_id = get_group(rel_dir) if rel_dir else root_group_id
    fref = add("PBXFileReference", "file:" + rel, {
        "isa": "PBXFileReference",
        "lastKnownFileType": "sourcecode.swift",
        "path": fname,
        "sourceTree": "<group>",
    })
    file_refs[rel] = fref
    pending_children.setdefault(group_id, []).append(fref)
    bf = add("PBXBuildFile", "build:" + rel, {
        "isa": "PBXBuildFile",
        "fileRef": fref,
    })
    build_files[rel] = bf

# Assets.xcassets
assets_build_id = None
for rel in resource_files:
    rel_dir = os.path.dirname(rel)
    fname = os.path.basename(rel)
    group_id = get_group(rel_dir) if rel_dir else root_group_id
    fref = add("PBXFileReference", "file:" + rel, {
        "isa": "PBXFileReference",
        "lastKnownFileType": "folder.assetcatalog",
        "path": fname,
        "sourceTree": "<group>",
    })
    file_refs[rel] = fref
    pending_children.setdefault(group_id, []).append(fref)
    bf = add("PBXBuildFile", "build:" + rel, {
        "isa": "PBXBuildFile",
        "fileRef": fref,
    })
    build_files[rel] = bf
    assets_build_id = bf

# Info.plist (referenced via build setting, but still add file reference for visibility)
plist_fref = None
if plist_path:
    rel_dir = os.path.dirname(plist_path)
    fname = os.path.basename(plist_path)
    group_id = get_group(rel_dir) if rel_dir else root_group_id
    plist_fref = add("PBXFileReference", "file:" + plist_path, {
        "isa": "PBXFileReference",
        "lastKnownFileType": "text.plist.xml",
        "path": fname,
        "sourceTree": "<group>",
    })
    pending_children.setdefault(group_id, []).append(plist_fref)

# Now resolve children for every group (attach pending_children)
for gid, children in pending_children.items():
    for o in objects:
        if o.oid == gid:
            o.fields["children"].extend(children)
            break

# Products group + app file reference
products_group_id = add("PBXGroup", "group:Products", {
    "isa": "PBXGroup",
    "children": [],
    "sourceTree": "<group>",
    "name": "Products",
})

app_product_ref = add("PBXFileReference", "product:VeriPhone.app", {
    "isa": "PBXFileReference",
    "explicitFileType": "wrapper.application",
    "includeInIndex": "0",
    "path": "VeriPhone.app",
    "sourceTree": "BUILT_PRODUCTS_DIR",
})
for o in objects:
    if o.oid == products_group_id:
        o.fields["children"].append(app_product_ref)

# Main group containing VeriPhone source group + Products group
main_group_id = add("PBXGroup", "group:Main", {
    "isa": "PBXGroup",
    "children": [root_group_id, products_group_id],
    "sourceTree": "<group>",
})

# Build phases
sources_build_ids = [build_files[r] for r in swift_files]
resources_build_ids = [build_files[r] for r in resource_files]

sources_phase_id = add("PBXSourcesBuildPhase", "phase:Sources", {
    "isa": "PBXSourcesBuildPhase",
    "buildActionMask": "2147483647",
    "files": sources_build_ids,
    "runOnlyForDeploymentPostprocessing": "0",
})

resources_phase_id = add("PBXResourcesBuildPhase", "phase:Resources", {
    "isa": "PBXResourcesBuildPhase",
    "buildActionMask": "2147483647",
    "files": resources_build_ids,
    "runOnlyForDeploymentPostprocessing": "0",
})

frameworks_phase_id = add("PBXFrameworksBuildPhase", "phase:Frameworks", {
    "isa": "PBXFrameworksBuildPhase",
    "buildActionMask": "2147483647",
    "files": [],
    "runOnlyForDeploymentPostprocessing": "0",
})

# Build configurations
def make_build_config(name, is_debug):
    common = {
        "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
        "CLANG_ENABLE_MODULES": "YES",
        "CLANG_ENABLE_OBJC_ARC": "YES",
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": "1",
        "ENABLE_PREVIEWS": "YES",
        "GENERATE_INFOPLIST_FILE": "YES",
        "INFOPLIST_FILE": "VeriPhone/Resources/Info.plist",
        "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
        "INFOPLIST_KEY_UILaunchScreen_Generation": "YES",
        "INFOPLIST_KEY_UISupportedInterfaceOrientations": "UIInterfaceOrientationPortrait",
        "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
        "MARKETING_VERSION": "1.0",
        "PRODUCT_BUNDLE_IDENTIFIER": BUNDLE_ID,
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "SDKROOT": "iphoneos",
        "SWIFT_EMIT_LOC_STRINGS": "YES",
        "SWIFT_VERSION": "5.0",
        "TARGETED_DEVICE_FAMILY": "1",
        "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
        "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
        "DEVELOPMENT_TEAM": "",
    }
    if is_debug:
        common.update({
            "DEBUG_INFORMATION_FORMAT": "dwarf",
            "GCC_OPTIMIZATION_LEVEL": "0",
            "ONLY_ACTIVE_ARCH": "YES",
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
            "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
        })
    else:
        common.update({
            "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
            "SWIFT_COMPILATION_MODE": "wholemodule",
            "VALIDATE_PRODUCT": "YES",
        })
    return add("XCBuildConfiguration", "buildcfg:" + name, {
        "isa": "XCBuildConfiguration",
        "buildSettings": common,
        "name": name,
    })

target_debug_cfg = make_build_config("Debug", True)
target_release_cfg = make_build_config("Release", False)

def make_project_build_config(name, is_debug):
    common = {
        "ALWAYS_SEARCH_USER_PATHS": "NO",
        "CLANG_ANALYZER_NONNULL": "YES",
        "CLANG_ENABLE_MODULES": "YES",
        "CLANG_ENABLE_OBJC_ARC": "YES",
        "CLANG_WARN_DOCUMENTATION_COMMENTS": "YES",
        "CLANG_WARN_UNREACHABLE_CODE": "YES",
        "CLANG_WARN__DUPLICATE_METHOD_MATCH": "YES",
        "COPY_PHASE_STRIP": "NO",
        "ENABLE_STRICT_OBJC_MSGSEND": "YES",
        "GCC_C_LANGUAGE_STANDARD": "gnu17",
        "GCC_NO_COMMON_BLOCKS": "YES",
        "GCC_WARN_64_TO_32_BIT_CONVERSION": "YES",
        "GCC_WARN_UNUSED_VARIABLE": "YES",
        "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
        "MTL_FAST_MATH": "YES",
        "SDKROOT": "iphoneos",
        "SWIFT_VERSION": "5.0",
        "SWIFT_STRICT_CONCURRENCY": "complete",
    }
    if is_debug:
        common.update({
            "DEBUG_INFORMATION_FORMAT": "dwarf",
            "ENABLE_TESTABILITY": "YES",
            "GCC_OPTIMIZATION_LEVEL": "0",
            "GCC_PREPROCESSOR_DEFINITIONS": ["DEBUG=1", "$(inherited)"],
            "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
            "ONLY_ACTIVE_ARCH": "YES",
            "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
        })
    else:
        common.update({
            "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
            "MTL_ENABLE_DEBUG_INFO": "NO",
            "SWIFT_COMPILATION_MODE": "wholemodule",
            "VALIDATE_PRODUCT": "YES",
        })
    return add("XCBuildConfiguration", "projectcfg:" + name, {
        "isa": "XCBuildConfiguration",
        "buildSettings": common,
        "name": name,
    })

project_debug_cfg = make_project_build_config("Debug", True)
project_release_cfg = make_project_build_config("Release", False)

target_cfg_list = add("XCConfigurationList", "cfglist:target", {
    "isa": "XCConfigurationList",
    "buildConfigurations": [target_debug_cfg, target_release_cfg],
    "defaultConfigurationIsVisible": "0",
    "defaultConfigurationName": "Release",
})

project_cfg_list = add("XCConfigurationList", "cfglist:project", {
    "isa": "XCConfigurationList",
    "buildConfigurations": [project_debug_cfg, project_release_cfg],
    "defaultConfigurationIsVisible": "0",
    "defaultConfigurationName": "Release",
})

native_target_id = add("PBXNativeTarget", "target:VeriPhone", {
    "isa": "PBXNativeTarget",
    "buildConfigurationList": target_cfg_list,
    "buildPhases": [sources_phase_id, frameworks_phase_id, resources_phase_id],
    "buildRules": [],
    "dependencies": [],
    "name": PROJECT_NAME,
    "productName": PROJECT_NAME,
    "productReference": app_product_ref,
    "productType": "com.apple.product-type.application",
})

project_id = add("PBXProject", "project:root", {
    "isa": "PBXProject",
    "attributes": {
        "BuildIndependentTargetsInParallel": "1",
        "LastSwiftUpdateCheck": "1600",
        "LastUpgradeCheck": "1600",
        "TargetAttributes": {
            native_target_id: {
                "CreatedOnToolsVersion": "16.0",
            }
        },
    },
    "buildConfigurationList": project_cfg_list,
    "compatibilityVersion": "Xcode 14.0",
    "developmentRegion": "es",
    "hasScannedForEncodings": "0",
    "knownRegions": ["es", "Base"],
    "mainGroup": main_group_id,
    "minimizedProjectReferenceProxies": "1",
    "preferredProjectObjectVersion": "77",
    "productRefGroup": products_group_id,
    "projectDirPath": "",
    "projectRoot": "",
    "targets": [native_target_id],
})

# ---------- Serialize to pbxproj text ----------

def fmt_string(s):
    if s == "":
        return '""'
    needs_quotes = False
    for ch in s:
        if not (ch.isalnum() or ch in "_/.$"):
            needs_quotes = True
            break
    if s[0].isdigit():
        needs_quotes = True
    if not needs_quotes:
        return s
    escaped = s.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'

def fmt_value(v, indent):
    pad = "\t" * indent
    pad_in = "\t" * (indent + 1)
    if isinstance(v, dict):
        lines = ["{"]
        for k in sorted(v.keys()):
            lines.append(f"{pad_in}{fmt_string(str(k))} = {fmt_value(v[k], indent + 1)};")
        lines.append(f"{pad}}}")
        return "\n".join(lines)
    if isinstance(v, list):
        if not v:
            return "(\n\t" + pad + ");".rstrip(";")[:-0] if False else "(\n" + pad + ")"
        lines = ["("]
        for item in v:
            lines.append(f"{pad_in}{fmt_value(item, indent + 1)},")
        lines.append(f"{pad})")
        return "\n".join(lines)
    return fmt_string(str(v))

out_lines = []
out_lines.append("// !$*UTF8*$!")
out_lines.append("{")
out_lines.append("\tarchiveVersion = 1;")
out_lines.append("\tclasses = {")
out_lines.append("\t};")
out_lines.append("\tobjectVersion = 77;")
out_lines.append("\tobjects = {")

by_isa = {}
for o in objects:
    by_isa.setdefault(o.isa, []).append(o)

for isa in sorted(by_isa.keys()):
    out_lines.append(f"\n/* Begin {isa} section */")
    for o in sorted(by_isa[isa], key=lambda x: x.oid):
        fields = {k: v for k, v in o.fields.items() if k != "isa"}
        out_lines.append(f"\t\t{o.oid} /* {isa} */ = {{")
        out_lines.append(f"\t\t\tisa = {isa};")
        for k in sorted(fields.keys()):
            out_lines.append(f"\t\t\t{fmt_string(k)} = {fmt_value(fields[k], 3)};")
        out_lines.append("\t\t};")
    out_lines.append(f"/* End {isa} section */")

out_lines.append("\t};")
out_lines.append(f"\trootObject = {project_id} /* Project object */;")
out_lines.append("}")
out_lines.append("")

pbxproj_text = "\n".join(out_lines)

xcodeproj_dir = os.path.join(ROOT, f"{PROJECT_NAME}.xcodeproj")
os.makedirs(xcodeproj_dir, exist_ok=True)
with open(os.path.join(xcodeproj_dir, "project.pbxproj"), "w", encoding="utf-8", newline="\n") as f:
    f.write(pbxproj_text)

# workspace
workspace_dir = os.path.join(xcodeproj_dir, "project.xcworkspace")
os.makedirs(workspace_dir, exist_ok=True)
with open(os.path.join(workspace_dir, "contents.xcworkspacedata"), "w", encoding="utf-8", newline="\n") as f:
    f.write('<?xml version="1.0" encoding="UTF-8"?>\n<Workspace\n   version = "1.0">\n   <FileRef\n      location = "self:">\n   </FileRef>\n</Workspace>\n')

print(f"Generated {os.path.join(xcodeproj_dir, 'project.pbxproj')}")
print(f"Swift files included: {len(swift_files)}")
print(f"Resource refs included: {len(resource_files)}")
