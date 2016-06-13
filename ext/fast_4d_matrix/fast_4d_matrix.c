#include "ruby.h"
#include <math.h>
#include <immintrin.h>
VALUE Fast4DMatrix = Qnil;
VALUE Vec3 = Qnil;
VALUE Matrix4Sym = Qnil;

// method declarations
void Init_fast_4d_matrix();
VALUE Vec3_singleton_method_from_a(VALUE self, VALUE rbx, VALUE rby, VALUE rbz);
VALUE Vec3_method_to_a(VALUE self);
VALUE Vec3_method_r(VALUE self);
VALUE Vec3_method_r2(VALUE self);
VALUE Vec3_method_dot(VALUE self, VALUE other);
VALUE Vec3_method_cos(VALUE self, VALUE other);
VALUE Vec3_method_cross(VALUE self, VALUE other);
VALUE Vec3_method_add(VALUE self, VALUE other);
VALUE Vec3_method_unary_positive(VALUE self);
VALUE Vec3_method_unary_negtive(VALUE self);
VALUE Vec3_method_sub(VALUE self, VALUE other);
VALUE Vec3_method_mul(VALUE self, VALUE other);
VALUE Vec3_method_div(VALUE self, VALUE other);
VALUE Vec3_method_add_bang(VALUE self, VALUE other);
VALUE Vec3_method_sub_bang(VALUE self, VALUE other);
VALUE Vec3_method_mul_bang(VALUE self, VALUE other);
VALUE Vec3_method_normalize(VALUE self);
VALUE Vec3_method_normalize_bang(VALUE self);

void Init_fast_4d_matrix() {
  Fast4DMatrix = rb_define_module("Fast4DMatrix");

  Vec3 = rb_define_class_under(Fast4DMatrix, "Vec3", rb_cObject);
  rb_define_singleton_method(Vec3, "from_a", Vec3_singleton_method_from_a, 3);
  rb_define_method(Vec3, "to_a", Vec3_method_to_a, 0);
  rb_define_method(Vec3, "r", Vec3_method_r, 0);
  rb_define_method(Vec3, "r2", Vec3_method_r2, 0);
  rb_define_method(Vec3, "dot", Vec3_method_dot, 1);
  rb_define_method(Vec3, "cos", Vec3_method_cos, 1);
  rb_define_method(Vec3, "cross", Vec3_method_cross, 1);
  rb_define_method(Vec3, "add", Vec3_method_add, 1);
  rb_define_method(Vec3, "sub", Vec3_method_sub, 1);
  rb_define_method(Vec3, "mul", Vec3_method_mul, 1);
  rb_define_method(Vec3, "div", Vec3_method_div, 1);
  rb_define_method(Vec3, "add!", Vec3_method_add_bang, 1);
  rb_define_method(Vec3, "sub!", Vec3_method_sub_bang, 1);
  rb_define_method(Vec3, "mul!", Vec3_method_mul_bang, 1);
  rb_define_method(Vec3, "+@", Vec3_method_unary_positive, 0);
  rb_define_method(Vec3, "-@", Vec3_method_unary_negtive, 0);
  rb_define_alias(Vec3, "+", "add");
  rb_define_alias(Vec3, "-", "sub");
  rb_define_alias(Vec3, "*", "mul");
  rb_define_alias(Vec3, "/", "div");
  rb_define_method(Vec3, "normalize", Vec3_method_normalize, 0);
  rb_define_method(Vec3, "normalize!", Vec3_method_normalize_bang, 0);
}

typedef struct TVec3Type {
  double values[3];
  double r;
} Vec3Type;

VALUE Vec3_c_create(double x, double y, double z, Vec3Type** data) {
  Vec3Type *v = malloc(sizeof(Vec3Type));
  v->values[0] = x;
  v->values[1] = y;
  v->values[2] = z;
  v->r = sqrt(x * x + y * y + z * z); 
  VALUE ret = Data_Wrap_Struct(Vec3, 0, free, v);
  if (data) {
    *data = v;
  }
  return ret;
}

VALUE Vec3_singleton_method_from_a(VALUE clazz, VALUE rbx, VALUE rby, VALUE rbz) {
  Vec3Type *v = malloc(sizeof(Vec3Type));
  double x, y, z;
  v->values[0] = x = RFLOAT_VALUE(rbx);
  v->values[1] = y = RFLOAT_VALUE(rby);
  v->values[2] = z = RFLOAT_VALUE(rbz);
  v->r = sqrt(x * x + y * y + z * z); 
  VALUE ret = Data_Wrap_Struct(Vec3, 0, free, v);
  return ret;
}

VALUE Vec3_method_to_a(VALUE self) {
  Vec3Type *v;
  Data_Get_Struct(self, Vec3Type, v);

  VALUE ret = rb_ary_new();
  rb_ary_push(ret, rb_float_new(v->values[0]));
  rb_ary_push(ret, rb_float_new(v->values[1]));
  rb_ary_push(ret, rb_float_new(v->values[2]));

  return ret;
}

VALUE Vec3_method_dot(VALUE self, VALUE other) {
  Vec3Type *v1, *v2;
  Data_Get_Struct(self, Vec3Type, v1);
  Data_Get_Struct(other, Vec3Type, v2);

  double ret = 0;
  ret += v1->values[0] * v2->values[0];
  ret += v1->values[1] * v2->values[1];
  ret += v1->values[2] * v2->values[2];
  return rb_float_new(ret);
}
VALUE Vec3_method_cos(VALUE self, VALUE other) { 
  Vec3Type *v1, *v2;
  Data_Get_Struct(self, Vec3Type, v1);
  Data_Get_Struct(other, Vec3Type, v2);

  double ret = 0, r1, r2;
  ret += v1->values[0] * v2->values[0];
  ret += v1->values[1] * v2->values[1];
  ret += v1->values[2] * v2->values[2];

  r1 = v1->values[0] * v1->values[0] + v1->values[1] * v1->values[1] + v1->values[2] * v1->values[2];

  r2 = v2->values[0] * v2->values[0] + v2->values[1] * v2->values[1] + v2->values[2] * v2->values[2];

  if (r1 == 0 || r2 == 0)
    rb_raise(rb_eRuntimeError, "zero vector detected!");

  return rb_float_new(sqrt(ret*ret / r1 / r2));
}

VALUE Vec3_method_cross(VALUE self, VALUE other) {
  Vec3Type *v1, *v2; Data_Get_Struct(self, Vec3Type, v1);
  Data_Get_Struct(other, Vec3Type, v2);
 
  double x, y, z;
  x = v1->values[1] * v2->values[2] - v1->values[2] * v2->values[1];
  y = v1->values[2] * v2->values[0] - v1->values[0] * v2->values[2];
  z = v1->values[0] * v2->values[1] - v1->values[1] * v2->values[0];
  
  return Vec3_c_create(x, y, z, NULL);
}

VALUE Vec3_method_unary_positive(VALUE self) {
  Vec3Type *v1;
  Data_Get_Struct(self, Vec3Type, v1);
 
  double x, y, z;
  x = v1->values[0];
  y = v1->values[1];
  z = v1->values[2];
  
  return Vec3_c_create(x, y, z, NULL);
}
VALUE Vec3_method_unary_negtive(VALUE self) {
  Vec3Type *v1;
  Data_Get_Struct(self, Vec3Type, v1);
 
  double x, y, z;
  x = -v1->values[0];
  y = -v1->values[1];
  z = -v1->values[2];
  
  return Vec3_c_create(x, y, z, NULL);
}

VALUE Vec3_method_add(VALUE self, VALUE other) {
  Vec3Type *v1, *v2; Data_Get_Struct(self, Vec3Type, v1);
  Data_Get_Struct(other, Vec3Type, v2);
 
  double x, y, z;
  x = v1->values[0] + v2->values[0];
  y = v1->values[1] + v2->values[1];
  z = v1->values[2] + v2->values[2];
  
  return Vec3_c_create(x, y, z, NULL);
}

VALUE Vec3_method_sub(VALUE self, VALUE other) {
  Vec3Type *v1, *v2; Data_Get_Struct(self, Vec3Type, v1);
  Data_Get_Struct(other, Vec3Type, v2);

  double x, y, z;
  x = v1->values[0] - v2->values[0];
  y = v1->values[1] - v2->values[1];
  z = v1->values[2] - v2->values[2];

  return Vec3_c_create(x, y, z, NULL);
}

VALUE Vec3_method_mul(VALUE self, VALUE other){
  Vec3Type *v1, *v2; 
  Data_Get_Struct(self, Vec3Type, v1);
  double x, y, z;
  if (TYPE(other) == T_FLOAT) {
    double val = NUM2DBL(other);
    x = v1->values[0] * val;
    y = v1->values[1] * val;
    z = v1->values[2] * val;
  }
  else {
    Data_Get_Struct(other, Vec3Type, v2);

    x = v1->values[0] * v2->values[0];
    y = v1->values[1] * v2->values[1];
    z = v1->values[2] * v2->values[2];
  }
  return Vec3_c_create(x, y, z, NULL);
}
VALUE Vec3_method_div(VALUE self, VALUE other){
  Vec3Type *v1; 
  Data_Get_Struct(self, Vec3Type, v1);
  double x, y, z;
  if (TYPE(other) == T_FLOAT) {
    double val = NUM2DBL(other);
    x = v1->values[0] / val;
    y = v1->values[1] / val;
    z = v1->values[2] / val;
  }
  else {
    rb_raise(rb_eArgError, "parameter must be float");
    return Qnil;
  }
  return Vec3_c_create(x, y, z, NULL);
}

void Vec3_c_recalc_r(Vec3Type *v) {
  v->r = sqrt(v->values[0]*v->values[0]+v->values[1]*v->values[1]+v->values[2]*v->values[2]);
}

VALUE Vec3_method_add_bang(VALUE self, VALUE other){
  Vec3Type *v1, *v2; Data_Get_Struct(self, Vec3Type, v1);
  Data_Get_Struct(other, Vec3Type, v2);
 
  v1->values[0] += v2->values[0];
  v1->values[1] += v2->values[1];
  v1->values[2] += v2->values[2];
  Vec3_c_recalc_r(v1);

  return self;
}

VALUE Vec3_method_sub_bang(VALUE self, VALUE other){
  Vec3Type *v1, *v2; Data_Get_Struct(self, Vec3Type, v1);
  Data_Get_Struct(other, Vec3Type, v2);
 
  v1->values[0] -= v2->values[0];
  v1->values[1] -= v2->values[1];
  v1->values[2] -= v2->values[2];
  Vec3_c_recalc_r(v1);
  return self;
}

VALUE Vec3_method_mul_bang(VALUE self, VALUE other){
  Vec3Type *v1, *v2; 
  Data_Get_Struct(self, Vec3Type, v1);
  if (TYPE(other) == T_FLOAT) {
    double val = NUM2DBL(other);
    v1->values[0] *= val;
    v1->values[1] *= val;
    v1->values[2] *= val;
  
  }
  else {
    Data_Get_Struct(other, Vec3Type, v2);
   
    v1->values[0] *= v2->values[0];
    v1->values[1] *= v2->values[1];
    v1->values[2] *= v2->values[2];
  }
  
  Vec3_c_recalc_r(v1);
  return self;
}

VALUE Vec3_method_r(VALUE self) {
  Vec3Type *v1; 
  Data_Get_Struct(self, Vec3Type, v1);
  return rb_float_new(v1->r);
}
VALUE Vec3_method_r2(VALUE self) {
  Vec3Type *v1; 
  Data_Get_Struct(self, Vec3Type, v1);
  return rb_float_new(v1->r * v1->r);
}

VALUE Vec3_method_normalize(VALUE self) {
  Vec3Type *v1;
  Data_Get_Struct(self, Vec3Type, v1);
  double r = sqrt(v1->values[0]*v1->values[0]+v1->values[1]*v1->values[1]+v1->values[2]*v1->values[2]);
  if (r == 0)
    rb_raise(rb_eRuntimeError, "zero vector detected");
  return Vec3_c_create(v1->values[0]/r, v1->values[1]/r, v1->values[2]/r, NULL);
}
VALUE Vec3_method_normalize_bang(VALUE self) {
  Vec3Type *v1;
  Data_Get_Struct(self, Vec3Type, v1);
  double r = sqrt(v1->values[0]*v1->values[0]+v1->values[1]*v1->values[1]+v1->values[2]*v1->values[2]);
  if (r == 0)
    rb_raise(rb_eRuntimeError, "zero vector detected");
  v1->values[0] /= r;
  v1->values[1] /= r;
  v1->values[2] /= r;
  v1->r = 1;
  return self;
}
