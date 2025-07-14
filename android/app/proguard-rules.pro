-keep class dev.fluttercommunity.plus.connectivity.** { *; }
-keep class androidx.core.net.** { *; }
-dontwarn dev.fluttercommunity.plus.connectivity.**
-keep class com.github.barteksc.** { *; }
-keep class com.shockwave.** { *; }
-keep class com.joanzapata.pdfview.** { *; }
-keep class android.support.v4.** { *; }
-keep class androidx.** { *; }

# Optional (avoid reflection errors)
-dontwarn com.github.barteksc.**
-dontwarn com.shockwave.**

# Required for flutter_pdfview
-keep class com.shockwave.** { *; }
-dontwarn com.shockwave.**
