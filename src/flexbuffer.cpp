#include "flexbuffer.hpp"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <vector>
#include <cstring>

namespace godot_flatbuffers {

void FlexBuffer::_bind_methods() {
    godot::ClassDB::bind_static_method("FlexBuffer", godot::D_METHOD("encode", "variant"), &FlexBuffer::encode);
    godot::ClassDB::bind_static_method("FlexBuffer", godot::D_METHOD("decode", "bytes"), &FlexBuffer::decode);
    godot::ClassDB::bind_static_method("FlexBuffer", godot::D_METHOD("var_to_flex", "variant"), &FlexBuffer::var_to_flex);
    godot::ClassDB::bind_static_method("FlexBuffer", godot::D_METHOD("flex_to_var", "bytes"), &FlexBuffer::flex_to_var);
}

godot::PackedByteArray FlexBuffer::encode(const godot::Variant &p_variant) {
    flexbuffers::Builder fbb;
    _encode_variant(fbb, p_variant);
    fbb.Finish();
    const std::vector<uint8_t> &buf = fbb.GetBuffer();
    godot::PackedByteArray ret;
    ret.resize(buf.size());
    memcpy(ret.ptrw(), buf.data(), buf.size());
    return ret;
}

godot::Variant FlexBuffer::decode(const godot::PackedByteArray &p_bytes) {
    if (p_bytes.is_empty()) {
        return godot::Variant();
    }
    const flexbuffers::Reference ref = flexbuffers::GetRoot(p_bytes.ptr(), p_bytes.size());
    return _decode_reference(ref);
}

void FlexBuffer::_encode_variant(flexbuffers::Builder &fbb, const godot::Variant &p_variant) {
    switch (p_variant.get_type()) {
        case godot::Variant::NIL:
            fbb.Null();
            break;
        case godot::Variant::BOOL:
            fbb.Bool(p_variant.operator bool());
            break;
        case godot::Variant::INT:
            fbb.Int(static_cast<int64_t>(p_variant));
            break;
        case godot::Variant::FLOAT:
            fbb.Double(static_cast<double>(p_variant));
            break;
        case godot::Variant::STRING: {
            godot::String s = p_variant.operator godot::String();
            fbb.String(s.utf8().get_data());
        } break;
        case godot::Variant::STRING_NAME: {
            godot::StringName s = p_variant.operator godot::StringName();
            size_t start = fbb.StartMap();
            fbb.Key("__type__");
            fbb.String("StringName");
            fbb.Key("v");
            fbb.String(godot::String(s).utf8().get_data());
            fbb.EndMap(start);
        } break;
        case godot::Variant::NODE_PATH: {
            godot::NodePath s = p_variant.operator godot::NodePath();
            size_t start = fbb.StartMap();
            fbb.Key("__type__");
            fbb.String("NodePath");
            fbb.Key("v");
            fbb.String(godot::String(s).utf8().get_data());
            fbb.EndMap(start);
        } break;
        case godot::Variant::ARRAY: {
            godot::Array arr = p_variant.operator godot::Array();
            size_t start = fbb.StartVector();
            for (int i = 0; i < arr.size(); ++i) {
                _encode_variant(fbb, arr[i]);
            }
            fbb.EndVector(start, false, false);
        } break;
        case godot::Variant::DICTIONARY: {
            godot::Dictionary dict = p_variant.operator godot::Dictionary();
            size_t start = fbb.StartMap();
            godot::Array keys = dict.keys();
            keys.sort();
            for (int i = 0; i < keys.size(); ++i) {
                godot::Variant key = keys[i];
                godot::String key_str = key.operator godot::String();
                fbb.Key(key_str.utf8().get_data());
                _encode_variant(fbb, dict[key]);
            }
            fbb.EndMap(start);
        } break;
        case godot::Variant::PACKED_BYTE_ARRAY: {
            godot::PackedByteArray ba = p_variant.operator godot::PackedByteArray();
            size_t start = fbb.StartMap();
            fbb.Key("__type__");
            fbb.String("PackedByteArray");
            fbb.Key("v");
            fbb.Blob(ba.ptr(), ba.size());
            fbb.EndMap(start);
        } break;
        case godot::Variant::VECTOR2: {
            godot::Vector2 v = p_variant.operator godot::Vector2();
            size_t start = fbb.StartMap();
            fbb.Key("__type__");
            fbb.String("Vector2");
            fbb.Key("v");
            fbb.TypedVector([&]() {
                fbb.Float(v.x);
                fbb.Float(v.y);
            });
            fbb.EndMap(start);
        } break;
        case godot::Variant::VECTOR3: {
            godot::Vector3 v = p_variant.operator godot::Vector3();
            size_t start = fbb.StartMap();
            fbb.Key("__type__");
            fbb.String("Vector3");
            fbb.Key("v");
            fbb.TypedVector([&]() {
                fbb.Float(v.x);
                fbb.Float(v.y);
                fbb.Float(v.z);
            });
            fbb.EndMap(start);
        } break;
        case godot::Variant::COLOR: {
            godot::Color v = p_variant.operator godot::Color();
            size_t start = fbb.StartMap();
            fbb.Key("__type__");
            fbb.String("Color");
            fbb.Key("v");
            fbb.TypedVector([&]() {
                fbb.Float(v.r);
                fbb.Float(v.g);
                fbb.Float(v.b);
                fbb.Float(v.a);
            });
            fbb.EndMap(start);
        } break;
        case godot::Variant::RECT2: {
            godot::Rect2 v = p_variant.operator godot::Rect2();
            size_t start = fbb.StartMap();
            fbb.Key("__type__");
            fbb.String("Rect2");
            fbb.Key("v");
            fbb.TypedVector([&]() {
                fbb.Float(v.position.x);
                fbb.Float(v.position.y);
                fbb.Float(v.size.x);
                fbb.Float(v.size.y);
            });
            fbb.EndMap(start);
        } break;
        case godot::Variant::TRANSFORM2D: {
            godot::Transform2D v = p_variant.operator godot::Transform2D();
            size_t start = fbb.StartMap();
            fbb.Key("__type__");
            fbb.String("Transform2D");
            fbb.Key("v");
            fbb.TypedVector([&]() {
                fbb.Float(v[0].x);
                fbb.Float(v[0].y);
                fbb.Float(v[1].x);
                fbb.Float(v[1].y);
                fbb.Float(v[2].x);
                fbb.Float(v[2].y);
            });
            fbb.EndMap(start);
        } break;
        case godot::Variant::VECTOR4: {
            godot::Vector4 v = p_variant.operator godot::Vector4();
            size_t start = fbb.StartMap();
            fbb.Key("__type__");
            fbb.String("Vector4");
            fbb.Key("v");
            fbb.TypedVector([&]() {
                fbb.Float(v.x);
                fbb.Float(v.y);
                fbb.Float(v.z);
                fbb.Float(v.w);
            });
            fbb.EndMap(start);
        } break;
        case godot::Variant::PLANE: {
            godot::Plane v = p_variant.operator godot::Plane();
            size_t start = fbb.StartMap();
            fbb.Key("__type__");
            fbb.String("Plane");
            fbb.Key("v");
            fbb.TypedVector([&]() {
                fbb.Float(v.normal.x);
                fbb.Float(v.normal.y);
                fbb.Float(v.normal.z);
                fbb.Float(v.d);
            });
            fbb.EndMap(start);
        } break;
        case godot::Variant::QUATERNION: {
            godot::Quaternion v = p_variant.operator godot::Quaternion();
            size_t start = fbb.StartMap();
            fbb.Key("__type__");
            fbb.String("Quaternion");
            fbb.Key("v");
            fbb.TypedVector([&]() {
                fbb.Float(v.x);
                fbb.Float(v.y);
                fbb.Float(v.z);
                fbb.Float(v.w);
            });
            fbb.EndMap(start);
        } break;
        case godot::Variant::AABB: {
            godot::AABB v = p_variant.operator godot::AABB();
            size_t start = fbb.StartMap();
            fbb.Key("__type__");
            fbb.String("AABB");
            fbb.Key("v");
            fbb.TypedVector([&]() {
                fbb.Float(v.position.x);
                fbb.Float(v.position.y);
                fbb.Float(v.position.z);
                fbb.Float(v.size.x);
                fbb.Float(v.size.y);
                fbb.Float(v.size.z);
            });
            fbb.EndMap(start);
        } break;
        case godot::Variant::TRANSFORM3D: {
            godot::Transform3D v = p_variant.operator godot::Transform3D();
            size_t start = fbb.StartMap();
            fbb.Key("__type__");
            fbb.String("Transform3D");
            fbb.Key("v");
            fbb.TypedVector([&]() {
                for (int i = 0; i < 3; ++i) {
                    fbb.Float(v.basis[i].x);
                    fbb.Float(v.basis[i].y);
                    fbb.Float(v.basis[i].z);
                }
                fbb.Float(v.origin.x);
                fbb.Float(v.origin.y);
                fbb.Float(v.origin.z);
            });
            fbb.EndMap(start);
        } break;
        case godot::Variant::PACKED_INT32_ARRAY: {
            godot::PackedInt32Array v = p_variant.operator godot::PackedInt32Array();
            size_t start = fbb.StartMap();
            fbb.Key("__type__");
            fbb.String("PackedInt32Array");
            fbb.Key("v");
            fbb.TypedVector([&]() {
                for (int i = 0; i < v.size(); ++i) {
                    fbb.Int(v[i]);
                }
            });
            fbb.EndMap(start);
        } break;
        case godot::Variant::PACKED_INT64_ARRAY: {
            godot::PackedInt64Array v = p_variant.operator godot::PackedInt64Array();
            size_t start = fbb.StartMap();
            fbb.Key("__type__");
            fbb.String("PackedInt64Array");
            fbb.Key("v");
            fbb.TypedVector([&]() {
                for (int i = 0; i < v.size(); ++i) {
                    fbb.Int(v[i]);
                }
            });
            fbb.EndMap(start);
        } break;
        case godot::Variant::PACKED_FLOAT32_ARRAY: {
            godot::PackedFloat32Array v = p_variant.operator godot::PackedFloat32Array();
            size_t start = fbb.StartMap();
            fbb.Key("__type__");
            fbb.String("PackedFloat32Array");
            fbb.Key("v");
            fbb.TypedVector([&]() {
                for (int i = 0; i < v.size(); ++i) {
                    fbb.Float(v[i]);
                }
            });
            fbb.EndMap(start);
        } break;
        case godot::Variant::PACKED_FLOAT64_ARRAY: {
            godot::PackedFloat64Array v = p_variant.operator godot::PackedFloat64Array();
            size_t start = fbb.StartMap();
            fbb.Key("__type__");
            fbb.String("PackedFloat64Array");
            fbb.Key("v");
            fbb.TypedVector([&]() {
                for (int i = 0; i < v.size(); ++i) {
                    fbb.Double(v[i]);
                }
            });
            fbb.EndMap(start);
        } break;
        case godot::Variant::PACKED_STRING_ARRAY: {
            godot::PackedStringArray v = p_variant.operator godot::PackedStringArray();
            size_t start = fbb.StartMap();
            fbb.Key("__type__");
            fbb.String("PackedStringArray");
            fbb.Key("v");
            size_t vstart = fbb.StartVector();
            for (int i = 0; i < v.size(); ++i) {
                fbb.String(v[i].utf8().get_data());
            }
            fbb.EndVector(vstart, false, false);
            fbb.EndMap(start);
        } break;
        case godot::Variant::PACKED_VECTOR2_ARRAY: {
            godot::PackedVector2Array v = p_variant.operator godot::PackedVector2Array();
            size_t start = fbb.StartMap();
            fbb.Key("__type__");
            fbb.String("PackedVector2Array");
            fbb.Key("v");
            size_t vstart = fbb.StartVector();
            for (int i = 0; i < v.size(); ++i) {
                fbb.TypedVector([&]() {
                    fbb.Float(v[i].x);
                    fbb.Float(v[i].y);
                });
            }
            fbb.EndVector(vstart, false, false);
            fbb.EndMap(start);
        } break;
        case godot::Variant::PACKED_VECTOR3_ARRAY: {
            godot::PackedVector3Array v = p_variant.operator godot::PackedVector3Array();
            size_t start = fbb.StartMap();
            fbb.Key("__type__");
            fbb.String("PackedVector3Array");
            fbb.Key("v");
            size_t vstart = fbb.StartVector();
            for (int i = 0; i < v.size(); ++i) {
                fbb.TypedVector([&]() {
                    fbb.Float(v[i].x);
                    fbb.Float(v[i].y);
                    fbb.Float(v[i].z);
                });
            }
            fbb.EndVector(vstart, false, false);
            fbb.EndMap(start);
        } break;
        case godot::Variant::PACKED_COLOR_ARRAY: {
            godot::PackedColorArray v = p_variant.operator godot::PackedColorArray();
            size_t start = fbb.StartMap();
            fbb.Key("__type__");
            fbb.String("PackedColorArray");
            fbb.Key("v");
            size_t vstart = fbb.StartVector();
            for (int i = 0; i < v.size(); ++i) {
                fbb.TypedVector([&]() {
                    fbb.Float(v[i].r);
                    fbb.Float(v[i].g);
                    fbb.Float(v[i].b);
                    fbb.Float(v[i].a);
                });
            }
            fbb.EndVector(vstart, false, false);
            fbb.EndMap(start);
        } break;
        case godot::Variant::PACKED_VECTOR4_ARRAY: {
            godot::PackedVector4Array v = p_variant.operator godot::PackedVector4Array();
            size_t start = fbb.StartMap();
            fbb.Key("__type__");
            fbb.String("PackedVector4Array");
            fbb.Key("v");
            size_t vstart = fbb.StartVector();
            for (int i = 0; i < v.size(); ++i) {
                fbb.TypedVector([&]() {
                    fbb.Float(v[i].x);
                    fbb.Float(v[i].y);
                    fbb.Float(v[i].z);
                    fbb.Float(v[i].w);
                });
            }
            fbb.EndVector(vstart, false, false);
            fbb.EndMap(start);
        } break;
        case godot::Variant::OBJECT: {
            godot::Object *obj = p_variant.operator godot::Object *();
            if (!obj) {
                fbb.Null();
                break;
            }
            size_t start = fbb.StartMap();
            fbb.Key("__type__");
            fbb.String(obj->get_class().utf8().get_data());

            godot::TypedArray<godot::Dictionary> props = obj->get_property_list();
            for (int i = 0; i < props.size(); ++i) {
                godot::Dictionary p = props[i];
                uint32_t usage = p["usage"];
                if (usage & godot::PROPERTY_USAGE_STORAGE) {
                    godot::String name = p["name"];
                    fbb.Key(name.utf8().get_data());
                    _encode_variant(fbb, obj->get(name));
                }
            }
            fbb.EndMap(start);
        } break;
        default:
            fbb.Null();
            break;
    }
}

godot::Variant FlexBuffer::_decode_reference(const flexbuffers::Reference &ref) {
    if (ref.IsNull()) {
        return godot::Variant();
    } else if (ref.IsBool()) {
        return ref.AsBool();
    } else if (ref.IsInt()) {
        return static_cast<int64_t>(ref.AsInt64());
    } else if (ref.IsUInt()) {
        return static_cast<int64_t>(ref.AsUInt64());
    } else if (ref.IsFloat()) {
        return ref.AsDouble();
    } else if (ref.IsString()) {
        return godot::String(ref.AsString().c_str());
    } else if (ref.IsMap()) {
        flexbuffers::Map map = ref.AsMap();
        if (map.size() >= 1 && map["__type__"].IsString()) {
            godot::String type = map["__type__"].AsString().c_str();
            flexbuffers::Reference v = map["v"];
            if (type == "Vector2" && (v.IsTypedVector() || v.IsFixedTypedVector() || v.IsVector())) {
                flexbuffers::Vector vec = v.AsVector();
                godot::Vector2 gv;
                if (vec.size() >= 2) {
                    gv.x = vec[0].AsDouble();
                    gv.y = vec[1].AsDouble();
                }
                return gv;
            } else if (type == "StringName" && v.IsString()) {
                return godot::StringName(v.AsString().c_str());
            } else if (type == "NodePath" && v.IsString()) {
                return godot::NodePath(v.AsString().c_str());
            } else if (type == "Vector3" && (v.IsTypedVector() || v.IsFixedTypedVector() || v.IsVector())) {
                flexbuffers::Vector vec = v.AsVector();
                godot::Vector3 gv;
                if (vec.size() >= 3) {
                    gv.x = vec[0].AsDouble();
                    gv.y = vec[1].AsDouble();
                    gv.z = vec[2].AsDouble();
                }
                return gv;
            } else if (type == "Color" && (v.IsTypedVector() || v.IsFixedTypedVector() || v.IsVector())) {
                flexbuffers::Vector vec = v.AsVector();
                godot::Color gv;
                if (vec.size() >= 4) {
                    gv.r = static_cast<float>(vec[0].AsDouble());
                    gv.g = static_cast<float>(vec[1].AsDouble());
                    gv.b = static_cast<float>(vec[2].AsDouble());
                    gv.a = static_cast<float>(vec[3].AsDouble());
                }
                return gv;
            } else if (type == "Rect2" && (v.IsTypedVector() || v.IsFixedTypedVector() || v.IsVector())) {
                flexbuffers::Vector vec = v.AsVector();
                godot::Rect2 gv;
                if (vec.size() >= 4) {
                    gv.position.x = vec[0].AsDouble();
                    gv.position.y = vec[1].AsDouble();
                    gv.size.x = vec[2].AsDouble();
                    gv.size.y = vec[3].AsDouble();
                }
                return gv;
            } else if (type == "Transform2D" && (v.IsTypedVector() || v.IsFixedTypedVector() || v.IsVector())) {
                flexbuffers::Vector vec = v.AsVector();
                godot::Transform2D gv;
                if (vec.size() >= 6) {
                    gv[0].x = vec[0].AsDouble();
                    gv[0].y = vec[1].AsDouble();
                    gv[1].x = vec[2].AsDouble();
                    gv[1].y = vec[3].AsDouble();
                    gv[2].x = vec[4].AsDouble();
                    gv[2].y = vec[5].AsDouble();
                }
                return gv;
            } else if (type == "Vector4" && (v.IsTypedVector() || v.IsFixedTypedVector() || v.IsVector())) {
                flexbuffers::Vector vec = v.AsVector();
                godot::Vector4 gv;
                if (vec.size() >= 4) {
                    gv.x = vec[0].AsDouble();
                    gv.y = vec[1].AsDouble();
                    gv.z = vec[2].AsDouble();
                    gv.w = vec[3].AsDouble();
                }
                return gv;
            } else if (type == "Plane" && (v.IsTypedVector() || v.IsFixedTypedVector() || v.IsVector())) {
                flexbuffers::Vector vec = v.AsVector();
                godot::Plane gv;
                if (vec.size() >= 4) {
                    gv.normal.x = vec[0].AsDouble();
                    gv.normal.y = vec[1].AsDouble();
                    gv.normal.z = vec[2].AsDouble();
                    gv.d = vec[3].AsDouble();
                }
                return gv;
            } else if (type == "Quaternion" && (v.IsTypedVector() || v.IsFixedTypedVector() || v.IsVector())) {
                flexbuffers::Vector vec = v.AsVector();
                godot::Quaternion gv;
                if (vec.size() >= 4) {
                    gv.x = vec[0].AsDouble();
                    gv.y = vec[1].AsDouble();
                    gv.z = vec[2].AsDouble();
                    gv.w = vec[3].AsDouble();
                }
                return gv;
            } else if (type == "AABB" && (v.IsTypedVector() || v.IsFixedTypedVector() || v.IsVector())) {
                flexbuffers::Vector vec = v.AsVector();
                godot::AABB gv;
                if (vec.size() >= 6) {
                    gv.position.x = vec[0].AsDouble();
                    gv.position.y = vec[1].AsDouble();
                    gv.position.z = vec[2].AsDouble();
                    gv.size.x = vec[3].AsDouble();
                    gv.size.y = vec[4].AsDouble();
                    gv.size.z = vec[5].AsDouble();
                }
                return gv;
            } else if (type == "Transform3D" && (v.IsTypedVector() || v.IsFixedTypedVector() || v.IsVector())) {
                flexbuffers::Vector vec = v.AsVector();
                godot::Basis basis;
                godot::Vector3 origin;
                if (vec.size() >= 12) {
                    basis[0] = godot::Vector3(vec[0].AsDouble(), vec[1].AsDouble(), vec[2].AsDouble());
                    basis[1] = godot::Vector3(vec[3].AsDouble(), vec[4].AsDouble(), vec[5].AsDouble());
                    basis[2] = godot::Vector3(vec[6].AsDouble(), vec[7].AsDouble(), vec[8].AsDouble());
                    origin = godot::Vector3(vec[9].AsDouble(), vec[10].AsDouble(), vec[11].AsDouble());
                }
                return godot::Transform3D(basis, origin);
            } else if (type == "PackedByteArray" && v.IsBlob()) {
                flexbuffers::Blob blob = v.AsBlob();
                godot::PackedByteArray ba;
                ba.resize(static_cast<int>(blob.size()));
                memcpy(ba.ptrw(), blob.data(), blob.size());
                return ba;
            } else if (type == "PackedInt32Array" && (v.IsTypedVector() || v.IsVector())) {
                flexbuffers::Vector vec = v.AsVector();
                godot::PackedInt32Array arr;
                arr.resize(static_cast<int>(vec.size()));
                for (size_t i = 0; i < vec.size(); ++i) {
                    arr[static_cast<int>(i)] = vec[i].AsInt32();
                }
                return arr;
            } else if (type == "PackedInt64Array" && (v.IsTypedVector() || v.IsVector())) {
                flexbuffers::Vector vec = v.AsVector();
                godot::PackedInt64Array arr;
                arr.resize(static_cast<int>(vec.size()));
                for (size_t i = 0; i < vec.size(); ++i) {
                    arr[static_cast<int>(i)] = vec[i].AsInt64();
                }
                return arr;
            } else if (type == "PackedFloat32Array" && (v.IsTypedVector() || v.IsVector())) {
                flexbuffers::Vector vec = v.AsVector();
                godot::PackedFloat32Array arr;
                arr.resize(static_cast<int>(vec.size()));
                for (size_t i = 0; i < vec.size(); ++i) {
                    arr[static_cast<int>(i)] = vec[i].AsFloat();
                }
                return arr;
            } else if (type == "PackedFloat64Array" && (v.IsTypedVector() || v.IsVector())) {
                flexbuffers::Vector vec = v.AsVector();
                godot::PackedFloat64Array arr;
                arr.resize(static_cast<int>(vec.size()));
                for (size_t i = 0; i < vec.size(); ++i) {
                    arr[static_cast<int>(i)] = vec[i].AsDouble();
                }
                return arr;
            } else if (type == "PackedStringArray" && v.IsVector()) {
                flexbuffers::Vector vec = v.AsVector();
                godot::PackedStringArray arr;
                arr.resize(static_cast<int>(vec.size()));
                for (size_t i = 0; i < vec.size(); ++i) {
                    arr[static_cast<int>(i)] = vec[i].AsString().c_str();
                }
                return arr;
            } else if (type == "PackedVector2Array" && v.IsVector()) {
                flexbuffers::Vector vec = v.AsVector();
                godot::PackedVector2Array arr;
                arr.resize(static_cast<int>(vec.size()));
                for (size_t i = 0; i < vec.size(); ++i) {
                    flexbuffers::Reference v_ref = vec[i];
                    if (v_ref.IsTypedVector() || v_ref.IsFixedTypedVector() || v_ref.IsVector()) {
                        flexbuffers::Vector v2 = v_ref.AsVector();
                        if (v2.size() >= 2) {
                            arr[static_cast<int>(i)] = godot::Vector2(v2[0].AsDouble(), v2[1].AsDouble());
                        }
                    }
                }
                return arr;
            } else if (type == "PackedVector3Array" && v.IsVector()) {
                flexbuffers::Vector vec = v.AsVector();
                godot::PackedVector3Array arr;
                arr.resize(static_cast<int>(vec.size()));
                for (size_t i = 0; i < vec.size(); ++i) {
                    flexbuffers::Reference v_ref = vec[i];
                    if (v_ref.IsTypedVector() || v_ref.IsFixedTypedVector() || v_ref.IsVector()) {
                        flexbuffers::Vector v3 = v_ref.AsVector();
                        if (v3.size() >= 3) {
                            arr[static_cast<int>(i)] = godot::Vector3(v3[0].AsDouble(), v3[1].AsDouble(), v3[2].AsDouble());
                        }
                    }
                }
                return arr;
            } else if (type == "PackedColorArray" && v.IsVector()) {
                flexbuffers::Vector vec = v.AsVector();
                godot::PackedColorArray arr;
                arr.resize(static_cast<int>(vec.size()));
                for (size_t i = 0; i < vec.size(); ++i) {
                    flexbuffers::Reference v_ref = vec[i];
                    if (v_ref.IsTypedVector() || v_ref.IsFixedTypedVector() || v_ref.IsVector()) {
                        flexbuffers::Vector vc = v_ref.AsVector();
                        if (vc.size() >= 4) {
                            arr[static_cast<int>(i)] = godot::Color(static_cast<float>(vc[0].AsDouble()), static_cast<float>(vc[1].AsDouble()), static_cast<float>(vc[2].AsDouble()), static_cast<float>(vc[3].AsDouble()));
                        }
                    }
                }
                return arr;
            } else if (type == "PackedVector4Array" && v.IsVector()) {
                flexbuffers::Vector vec = v.AsVector();
                godot::PackedVector4Array arr;
                arr.resize(static_cast<int>(vec.size()));
                for (size_t i = 0; i < vec.size(); ++i) {
                    flexbuffers::Reference v_ref = vec[i];
                    if (v_ref.IsTypedVector() || v_ref.IsFixedTypedVector() || v_ref.IsVector()) {
                        flexbuffers::Vector v4 = v_ref.AsVector();
                        if (v4.size() >= 4) {
                            arr[static_cast<int>(i)] = godot::Vector4(v4[0].AsDouble(), v4[1].AsDouble(), v4[2].AsDouble(), v4[3].AsDouble());
                        }
                    }
                }
                return arr;
            } else {
                // Object handling
                godot::Object *obj = godot::ClassDB::instantiate(type);
                if (obj) {
                    flexbuffers::TypedVector keys = map.Keys();
                    for (size_t i = 0; i < keys.size(); ++i) {
                        godot::String key = keys[i].AsString().c_str();
                        if (key == "__type__") continue;
                        obj->set(key, _decode_reference(map[keys[i].AsKey()]));
                    }
                    godot::Variant *v_obj = memnew(godot::Variant(obj));
                    godot::Variant res = *v_obj;
                    memdelete(v_obj);
                    return res;
                }
            }
        }

        flexbuffers::TypedVector keys = map.Keys();
        godot::Dictionary *dict = memnew(godot::Dictionary);
        for (size_t i = 0; i < keys.size(); ++i) {
            godot::String key = keys[i].AsString().c_str();
            (*dict)[key] = _decode_reference(map[keys[i].AsKey()]);
        }
        godot::Variant res = *dict;
        memdelete(dict);
        return res;
    } else if (ref.IsVector() || ref.IsTypedVector() || ref.IsFixedTypedVector()) {
        flexbuffers::Vector vec = ref.AsVector();
        godot::Array *arr = memnew(godot::Array);
        arr->resize(static_cast<int>(vec.size()));
        for (size_t i = 0; i < vec.size(); ++i) {
            (*arr)[static_cast<int>(i)] = _decode_reference(vec[i]);
        }
        godot::Variant res = *arr;
        memdelete(arr);
        return res;
    } else if (ref.IsBlob()) {
        flexbuffers::Blob blob = ref.AsBlob();
        godot::PackedByteArray *ba = memnew(godot::PackedByteArray);
        ba->resize(static_cast<int>(blob.size()));
        memcpy(ba->ptrw(), blob.data(), blob.size());
        godot::Variant res = *ba;
        memdelete(ba);
        return res;
    }
    return godot::Variant();
}

} // namespace godot_flatbuffers
