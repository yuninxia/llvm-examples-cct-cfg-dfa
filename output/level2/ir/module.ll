; ModuleID = 'output/level2/ir/module.bc'
source_filename = "llvm-link"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%struct.Task = type { i32, i32, i32 }

@.str = private unnamed_addr constant [24 x i8] c"-- progress snapshot --\00", align 1
@.str.1 = private unnamed_addr constant [17 x i8] c"total weight=%d\0A\00", align 1
@.str.2 = private unnamed_addr constant [30 x i8] c"task #%d weight=%d fanout=%d\0A\00", align 1

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 {
  %1 = alloca i32, align 4
  %2 = alloca [5 x %struct.Task], align 16
  %3 = alloca i32, align 4
  store i32 0, ptr %1, align 4
  %4 = getelementptr inbounds [5 x %struct.Task], ptr %2, i64 0, i64 0
  call void @seed_tasks(ptr noundef %4, i64 noundef 5)
  %5 = getelementptr inbounds [5 x %struct.Task], ptr %2, i64 0, i64 0
  call void @log_progress(ptr noundef %5, i64 noundef 5)
  %6 = getelementptr inbounds [5 x %struct.Task], ptr %2, i64 0, i64 0
  %7 = call i32 @run_pipeline(ptr noundef %6, i64 noundef 5)
  store i32 %7, ptr %3, align 4
  %8 = load i32, ptr %3, align 4
  %9 = srem i32 %8, 17
  ret i32 %9
}

; Function Attrs: noinline nounwind uwtable
define internal void @seed_tasks(ptr noundef %0, i64 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i64, align 8
  %5 = alloca i64, align 8
  store ptr %0, ptr %3, align 8
  store i64 %1, ptr %4, align 8
  store i64 0, ptr %5, align 8
  br label %6

6:                                                ; preds = %33, %2
  %7 = load i64, ptr %5, align 8
  %8 = load i64, ptr %4, align 8
  %9 = icmp ult i64 %7, %8
  br i1 %9, label %10, label %36

10:                                               ; preds = %6
  %11 = load i64, ptr %5, align 8
  %12 = trunc i64 %11 to i32
  %13 = load ptr, ptr %3, align 8
  %14 = load i64, ptr %5, align 8
  %15 = getelementptr inbounds %struct.Task, ptr %13, i64 %14
  %16 = getelementptr inbounds %struct.Task, ptr %15, i32 0, i32 0
  store i32 %12, ptr %16, align 4
  %17 = load i64, ptr %5, align 8
  %18 = mul i64 %17, 3
  %19 = add i64 %18, 5
  %20 = trunc i64 %19 to i32
  %21 = load ptr, ptr %3, align 8
  %22 = load i64, ptr %5, align 8
  %23 = getelementptr inbounds %struct.Task, ptr %21, i64 %22
  %24 = getelementptr inbounds %struct.Task, ptr %23, i32 0, i32 1
  store i32 %20, ptr %24, align 4
  %25 = load i64, ptr %5, align 8
  %26 = urem i64 %25, 4
  %27 = add i64 %26, 2
  %28 = trunc i64 %27 to i32
  %29 = load ptr, ptr %3, align 8
  %30 = load i64, ptr %5, align 8
  %31 = getelementptr inbounds %struct.Task, ptr %29, i64 %30
  %32 = getelementptr inbounds %struct.Task, ptr %31, i32 0, i32 2
  store i32 %28, ptr %32, align 4
  br label %33

33:                                               ; preds = %10
  %34 = load i64, ptr %5, align 8
  %35 = add i64 %34, 1
  store i64 %35, ptr %5, align 8
  br label %6, !llvm.loop !6

36:                                               ; preds = %6
  ret void
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @fanout_walk(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store ptr %0, ptr %4, align 8
  store i32 %1, ptr %5, align 4
  %7 = load ptr, ptr %4, align 8
  %8 = icmp ne ptr %7, null
  br i1 %8, label %9, label %12

9:                                                ; preds = %2
  %10 = load i32, ptr %5, align 4
  %11 = icmp sle i32 %10, 0
  br i1 %11, label %12, label %13

12:                                               ; preds = %9, %2
  store i32 0, ptr %3, align 4
  br label %30

13:                                               ; preds = %9
  %14 = load ptr, ptr %4, align 8
  %15 = getelementptr inbounds %struct.Task, ptr %14, i32 0, i32 2
  %16 = load i32, ptr %15, align 4
  %17 = load i32, ptr %5, align 4
  %18 = srem i32 %16, %17
  %19 = add nsw i32 %18, 1
  store i32 %19, ptr %6, align 4
  %20 = load ptr, ptr %4, align 8
  %21 = getelementptr inbounds %struct.Task, ptr %20, i32 0, i32 1
  %22 = load i32, ptr %21, align 4
  %23 = load i32, ptr %6, align 4
  %24 = load ptr, ptr %4, align 8
  %25 = getelementptr inbounds %struct.Task, ptr %24, i32 0, i32 2
  %26 = load i32, ptr %25, align 4
  %27 = srem i32 %26, 5
  %28 = add nsw i32 %27, 1
  %29 = call i32 @depth_expand(i32 noundef %22, i32 noundef %23, i32 noundef %28)
  store i32 %29, ptr %3, align 4
  br label %30

30:                                               ; preds = %13, %12
  %31 = load i32, ptr %3, align 4
  ret i32 %31
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @depth_expand(i32 noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  store i32 %0, ptr %5, align 4
  store i32 %1, ptr %6, align 4
  store i32 %2, ptr %7, align 4
  %10 = load i32, ptr %6, align 4
  %11 = icmp sle i32 %10, 0
  br i1 %11, label %12, label %14

12:                                               ; preds = %3
  %13 = load i32, ptr %5, align 4
  store i32 %13, ptr %4, align 4
  br label %40

14:                                               ; preds = %3
  %15 = load i32, ptr %5, align 4
  %16 = load i32, ptr %7, align 4
  %17 = add nsw i32 %15, %16
  store i32 %17, ptr %8, align 4
  store i32 0, ptr %9, align 4
  br label %18

18:                                               ; preds = %35, %14
  %19 = load i32, ptr %9, align 4
  %20 = load i32, ptr %7, align 4
  %21 = icmp slt i32 %19, %20
  br i1 %21, label %22, label %38

22:                                               ; preds = %18
  %23 = load i32, ptr %5, align 4
  %24 = load i32, ptr %9, align 4
  %25 = add nsw i32 %23, %24
  %26 = add nsw i32 %25, 1
  %27 = load i32, ptr %6, align 4
  %28 = sub nsw i32 %27, 1
  %29 = load i32, ptr %7, align 4
  %30 = sdiv i32 %29, 2
  %31 = add nsw i32 %30, 1
  %32 = call i32 @depth_expand(i32 noundef %26, i32 noundef %28, i32 noundef %31)
  %33 = load i32, ptr %8, align 4
  %34 = add nsw i32 %33, %32
  store i32 %34, ptr %8, align 4
  br label %35

35:                                               ; preds = %22
  %36 = load i32, ptr %9, align 4
  %37 = add nsw i32 %36, 1
  store i32 %37, ptr %9, align 4
  br label %18, !llvm.loop !8

38:                                               ; preds = %18
  %39 = load i32, ptr %8, align 4
  store i32 %39, ptr %4, align 4
  br label %40

40:                                               ; preds = %38, %12
  %41 = load i32, ptr %4, align 4
  ret i32 %41
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @run_pipeline(ptr noundef %0, i64 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i64, align 8
  %5 = alloca i32, align 4
  %6 = alloca i64, align 8
  %7 = alloca ptr, align 8
  store ptr %0, ptr %3, align 8
  store i64 %1, ptr %4, align 8
  store i32 0, ptr %5, align 4
  store i64 0, ptr %6, align 8
  br label %8

8:                                                ; preds = %44, %2
  %9 = load i64, ptr %6, align 8
  %10 = load i64, ptr %4, align 8
  %11 = icmp ult i64 %9, %10
  br i1 %11, label %12, label %47

12:                                               ; preds = %8
  %13 = load ptr, ptr %3, align 8
  %14 = load i64, ptr %6, align 8
  %15 = getelementptr inbounds %struct.Task, ptr %13, i64 %14
  store ptr %15, ptr %7, align 8
  %16 = load ptr, ptr %7, align 8
  %17 = load i64, ptr %4, align 8
  %18 = load ptr, ptr %7, align 8
  %19 = getelementptr inbounds %struct.Task, ptr %18, i32 0, i32 1
  %20 = load i32, ptr %19, align 4
  %21 = srem i32 %20, 7
  %22 = sext i32 %21 to i64
  %23 = add i64 %17, %22
  %24 = trunc i64 %23 to i32
  %25 = call i32 @fanout_walk(ptr noundef %16, i32 noundef %24)
  %26 = load i32, ptr %5, align 4
  %27 = add nsw i32 %26, %25
  store i32 %27, ptr %5, align 4
  %28 = load i64, ptr %6, align 8
  %29 = trunc i64 %28 to i32
  %30 = srem i32 %29, 2
  %31 = icmp eq i32 %30, 0
  br i1 %31, label %32, label %43

32:                                               ; preds = %12
  %33 = load ptr, ptr %3, align 8
  %34 = load i64, ptr %4, align 8
  %35 = call i32 @sum_weights(ptr noundef %33, i64 noundef %34)
  %36 = load ptr, ptr %7, align 8
  %37 = getelementptr inbounds %struct.Task, ptr %36, i32 0, i32 2
  %38 = load i32, ptr %37, align 4
  %39 = add nsw i32 %38, 3
  %40 = srem i32 %35, %39
  %41 = load i32, ptr %5, align 4
  %42 = sub nsw i32 %41, %40
  store i32 %42, ptr %5, align 4
  br label %43

43:                                               ; preds = %32, %12
  br label %44

44:                                               ; preds = %43
  %45 = load i64, ptr %6, align 8
  %46 = add i64 %45, 1
  store i64 %46, ptr %6, align 8
  br label %8, !llvm.loop !9

47:                                               ; preds = %8
  %48 = load i32, ptr %5, align 4
  %49 = icmp slt i32 %48, 0
  br i1 %49, label %50, label %53

50:                                               ; preds = %47
  %51 = load i32, ptr %5, align 4
  %52 = sub nsw i32 0, %51
  store i32 %52, ptr %5, align 4
  br label %53

53:                                               ; preds = %50, %47
  %54 = load i32, ptr %5, align 4
  ret i32 %54
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @sum_weights(ptr noundef %0, i64 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i64, align 8
  %5 = alloca i32, align 4
  %6 = alloca i64, align 8
  store ptr %0, ptr %3, align 8
  store i64 %1, ptr %4, align 8
  store i32 0, ptr %5, align 4
  store i64 0, ptr %6, align 8
  br label %7

7:                                                ; preds = %19, %2
  %8 = load i64, ptr %6, align 8
  %9 = load i64, ptr %4, align 8
  %10 = icmp ult i64 %8, %9
  br i1 %10, label %11, label %22

11:                                               ; preds = %7
  %12 = load ptr, ptr %3, align 8
  %13 = load i64, ptr %6, align 8
  %14 = getelementptr inbounds %struct.Task, ptr %12, i64 %13
  %15 = getelementptr inbounds %struct.Task, ptr %14, i32 0, i32 1
  %16 = load i32, ptr %15, align 4
  %17 = load i32, ptr %5, align 4
  %18 = add nsw i32 %17, %16
  store i32 %18, ptr %5, align 4
  br label %19

19:                                               ; preds = %11
  %20 = load i64, ptr %6, align 8
  %21 = add i64 %20, 1
  store i64 %21, ptr %6, align 8
  br label %7, !llvm.loop !10

22:                                               ; preds = %7
  %23 = load i32, ptr %5, align 4
  ret i32 %23
}

; Function Attrs: noinline nounwind uwtable
define dso_local void @log_progress(ptr noundef %0, i64 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i64, align 8
  %5 = alloca i64, align 8
  store ptr %0, ptr %3, align 8
  store i64 %1, ptr %4, align 8
  %6 = call i32 @puts(ptr noundef @.str)
  store i64 0, ptr %5, align 8
  br label %7

7:                                                ; preds = %15, %2
  %8 = load i64, ptr %5, align 8
  %9 = load i64, ptr %4, align 8
  %10 = icmp ult i64 %8, %9
  br i1 %10, label %11, label %18

11:                                               ; preds = %7
  %12 = load ptr, ptr %3, align 8
  %13 = load i64, ptr %5, align 8
  %14 = getelementptr inbounds %struct.Task, ptr %12, i64 %13
  call void @print_task(ptr noundef %14)
  br label %15

15:                                               ; preds = %11
  %16 = load i64, ptr %5, align 8
  %17 = add i64 %16, 1
  store i64 %17, ptr %5, align 8
  br label %7, !llvm.loop !11

18:                                               ; preds = %7
  %19 = load ptr, ptr %3, align 8
  %20 = load i64, ptr %4, align 8
  %21 = call i32 @sum_weights(ptr noundef %19, i64 noundef %20)
  %22 = call i32 (ptr, ...) @printf(ptr noundef @.str.1, i32 noundef %21)
  ret void
}

declare i32 @puts(ptr noundef) #1

; Function Attrs: noinline nounwind uwtable
define internal void @print_task(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds %struct.Task, ptr %3, i32 0, i32 0
  %5 = load i32, ptr %4, align 4
  %6 = load ptr, ptr %2, align 8
  %7 = getelementptr inbounds %struct.Task, ptr %6, i32 0, i32 1
  %8 = load i32, ptr %7, align 4
  %9 = load ptr, ptr %2, align 8
  %10 = getelementptr inbounds %struct.Task, ptr %9, i32 0, i32 2
  %11 = load i32, ptr %10, align 4
  %12 = call i32 (ptr, ...) @printf(ptr noundef @.str.2, i32 noundef %5, i32 noundef %8, i32 noundef %11)
  ret void
}

declare i32 @printf(ptr noundef, ...) #1

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.ident = !{!0, !0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"clang version 17.0.6"}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"PIE Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = distinct !{!6, !7}
!7 = !{!"llvm.loop.mustprogress"}
!8 = distinct !{!8, !7}
!9 = distinct !{!9, !7}
!10 = distinct !{!10, !7}
!11 = distinct !{!11, !7}
