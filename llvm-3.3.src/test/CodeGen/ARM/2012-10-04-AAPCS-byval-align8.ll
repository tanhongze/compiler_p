; RUN: llc < %s -mtriple=armv7-none-linux-gnueabi | FileCheck %s
; Test that we correctly use registers and align elements when using va_arg

%struct_t = type { double, double, double }
@static_val = constant %struct_t { double 1.0, double 2.0, double 3.0 }

declare void @llvm.va_start(i8*) nounwind
declare void @llvm.va_end(i8*) nounwind

; CHECK: test_byval_8_bytes_alignment:
define void @test_byval_8_bytes_alignment(i32 %i, ...) {
entry:
; CHECK: stm     r0, {r1, r2, r3}
  %g = alloca i8*
  %g1 = bitcast i8** %g to i8*
  call void @llvm.va_start(i8* %g1)

; CHECK: add	[[REG:(r[0-9]+)|(lr)]], {{(r[0-9]+)|(lr)}}, #7
; CHECK: bfc	[[REG]], #0, #3
  %0 = va_arg i8** %g, double
  call void @llvm.va_end(i8* %g1)

  ret void
}

; CHECK: main:
; CHECK: ldm     r0, {r2, r3}
define i32 @main() {
entry:
  call void (i32, ...)* @test_byval_8_bytes_alignment(i32 555, %struct_t* byval @static_val)
  ret i32 0
}

declare void @f(double);

; CHECK:     test_byval_8_bytes_alignment_fixed_arg:
; CHECK-NOT:   str     r1
; CHECK:       str     r3, [sp, #12]
; CHECK:       str     r2, [sp, #8]
; CHECK-NOT:   str     r1
define void @test_byval_8_bytes_alignment_fixed_arg(i32 %n1, %struct_t* byval %val) nounwind {
entry:
  %a = getelementptr inbounds %struct_t* %val, i32 0, i32 0
  %0 = load double* %a
  call void (double)* @f(double %0)
  ret void
}

; CHECK: main_fixed_arg:
; CHECK: ldm     r0, {r2, r3}
define i32 @main_fixed_arg() {
entry:
  call void (i32, %struct_t*)* @test_byval_8_bytes_alignment_fixed_arg(i32 555, %struct_t* byval @static_val)
  ret i32 0
}

