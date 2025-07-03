package com.techwings.fmiscup

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.Toast

class AlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context?, intent: Intent?) {
        context?.let {
            Toast.makeText(it, "⏰ Alarm Triggered!", Toast.LENGTH_SHORT).show()
            Log.d("hllo","");
            try {
                NotificationFactory.fireNotification(it)
            } catch (e: Exception) {
                Toast.makeText(it, "Notification error: ${e.message}", Toast.LENGTH_SHORT).show()
            }
        }
    }
}
