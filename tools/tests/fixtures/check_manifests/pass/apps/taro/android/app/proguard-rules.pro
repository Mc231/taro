# App R8 rules (release). Library consumer rules are merged on top of these;
# add a rule here only for a release-only crash a library's own rules miss,
# and cover it in tools/check_manifests.py (r8-keep).

# Room creates every database through reflection: Class.forName("<Db>_Impl")
# then newInstance(). play-services-ads pulls WorkManager 2.7.0 with Room
# 2.2.5, whose consumer rule `-keep class * extends androidx.room.RoomDatabase`
# keeps the class but, under R8 full mode (default since AGP 8), not its
# constructor. WorkManager's startup initializer then dies before the first
# frame: "Failed to create an instance of androidx.work.impl.WorkDatabase"
# (docs/qa/round4_android_crash/REPORT.md, A4-01).
-keep class * extends androidx.room.RoomDatabase {
    <init>();
}
