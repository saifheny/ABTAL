package com.godot.game;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

public class AbtalNotificationReceiver extends BroadcastReceiver {
	@Override
	public void onReceive(Context context, Intent intent) {
		if (intent == null || intent.getAction() == null) {
			return;
		}
		String action = intent.getAction();
		if (AbtalNotificationHelper.ACTION_WELCOME.equals(action)) {
			AbtalNotificationHelper.showNotification(context, true);
		} else if (AbtalNotificationHelper.ACTION_INACTIVITY.equals(action)) {
			AbtalNotificationHelper.showNotification(context, false);
		} else if (Intent.ACTION_BOOT_COMPLETED.equals(action) || Intent.ACTION_MY_PACKAGE_REPLACED.equals(action)) {
			AbtalNotificationHelper.rescheduleOnBoot(context);
		}
	}
}
