package com.godot.game;

import android.app.Activity;
import android.app.AlarmManager;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Log;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.Locale;

public final class AbtalNotificationHelper {
	private static final String TAG = "AbtalNotif";
	public static final String CHANNEL_ID = "abtal_reminders";
	public static final String ACTION_WELCOME = "com.godot.game.ACTION_WELCOME_NOTIF";
	public static final String ACTION_INACTIVITY = "com.godot.game.ACTION_INACTIVITY_NOTIF";

	public static final int NOTIF_ID_WELCOME = 1001;
	public static final int NOTIF_ID_INACTIVITY = 1002;
	private static final int REQ_WELCOME = 7001;
	private static final int REQ_INACTIVITY = 7002;
	private static final int REQ_POST_NOTIF_PERM = 7101;

	private static final String PREFS = "abtal_notif_prefs";
	private static final String KEY_WELCOME_SCHEDULED = "welcome_scheduled";
	private static final String KEY_WELCOME_SHOWN = "welcome_shown";
	private static final String KEY_WELCOME_AT = "welcome_target_ms";
	private static final String KEY_INACTIVITY_AT = "inactivity_target_ms";
	private static final String KEY_PERM_ASKED = "perm_requested";

	public static final long WELCOME_DELAY_MS = 5L * 60L * 1000L; // 5 minutes
	public static final long INACTIVITY_DELAY_MS = 44L * 60L * 60L * 1000L; // 44 hours (~1.8 days)

	private AbtalNotificationHelper() {}

	public static void ensureChannel(Context ctx) {
		if (Build.VERSION.SDK_INT >= 26) {
			NotificationManager nm = (NotificationManager) ctx.getSystemService(Context.NOTIFICATION_SERVICE);
			if (nm == null) {
				return;
			}
			String lang = getLangCode(ctx);
			String chName = lang.equals("ar") ? "تذكيرات ومغامرات أبطال"
				: (lang.equals("fr") ? "Rappels ABTAL"
				: (lang.equals("de") ? "ABTAL Erinnerungen"
				: (lang.equals("it") ? "Promemoria ABTAL"
				: (lang.equals("es") ? "Recordatorios ABTAL"
				: (lang.equals("tr") ? "ABTAL Hatırlatmaları"
				: (lang.equals("zh") ? "ABTAL 冒险提醒" : "ABTAL Adventure Reminders"))))));
			NotificationChannel ch = new NotificationChannel(CHANNEL_ID, chName, NotificationManager.IMPORTANCE_DEFAULT);
			ch.enableLights(true);
			ch.setLightColor(0xFFE87A14);
			nm.createNotificationChannel(ch);
		}
	}

	public static void requestPermissionIfNeeded(Activity act) {
		if (Build.VERSION.SDK_INT < 33) {
			return;
		}
		SharedPreferences sp = act.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
		if (sp.getBoolean(KEY_PERM_ASKED, false)) {
			return;
		}
		if (act.checkSelfPermission("android.permission.POST_NOTIFICATIONS") != PackageManager.PERMISSION_GRANTED) {
			sp.edit().putBoolean(KEY_PERM_ASKED, true).apply();
			try {
				act.requestPermissions(new String[]{"android.permission.POST_NOTIFICATIONS"}, REQ_POST_NOTIF_PERM);
			} catch (Exception e) {
				Log.w(TAG, "requestPermissions failed: " + e.getMessage());
			}
		} else {
			sp.edit().putBoolean(KEY_PERM_ASKED, true).apply();
		}
	}

	public static void onAppOpened(Context ctx) {
		Context app = ctx.getApplicationContext();
		ensureChannel(app);
		NotificationManager nm = (NotificationManager) app.getSystemService(Context.NOTIFICATION_SERVICE);
		if (nm != null) {
			nm.cancel(NOTIF_ID_WELCOME);
			nm.cancel(NOTIF_ID_INACTIVITY);
		}

		SharedPreferences sp = app.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
		long now = System.currentTimeMillis();
		SharedPreferences.Editor ed = sp.edit();

		if (!sp.getBoolean(KEY_WELCOME_SCHEDULED, false)) {
			long welcomeAt = now + WELCOME_DELAY_MS;
			ed.putBoolean(KEY_WELCOME_SCHEDULED, true);
			ed.putLong(KEY_WELCOME_AT, welcomeAt);
			scheduleAlarm(app, ACTION_WELCOME, REQ_WELCOME, welcomeAt);
		}

		long inactivityAt = now + INACTIVITY_DELAY_MS;
		ed.putLong(KEY_INACTIVITY_AT, inactivityAt);
		ed.apply();
		scheduleAlarm(app, ACTION_INACTIVITY, REQ_INACTIVITY, inactivityAt);
	}

	public static void onAppBackgrounded(Context ctx) {
		Context app = ctx.getApplicationContext();
		ensureChannel(app);
		long inactivityAt = System.currentTimeMillis() + INACTIVITY_DELAY_MS;
		app.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
			.edit()
			.putLong(KEY_INACTIVITY_AT, inactivityAt)
			.apply();
		scheduleAlarm(app, ACTION_INACTIVITY, REQ_INACTIVITY, inactivityAt);
	}

	public static void rescheduleOnBoot(Context ctx) {
		Context app = ctx.getApplicationContext();
		ensureChannel(app);
		SharedPreferences sp = app.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
		long now = System.currentTimeMillis();

		if (sp.getBoolean(KEY_WELCOME_SCHEDULED, false) && !sp.getBoolean(KEY_WELCOME_SHOWN, false)) {
			long welcomeAt = sp.getLong(KEY_WELCOME_AT, 0L);
			if (welcomeAt > now) {
				scheduleAlarm(app, ACTION_WELCOME, REQ_WELCOME, welcomeAt);
			} else if (welcomeAt > 0L) {
				showNotification(app, true);
			}
		}

		long inactAt = sp.getLong(KEY_INACTIVITY_AT, 0L);
		if (inactAt <= 0L) {
			inactAt = now + INACTIVITY_DELAY_MS;
			sp.edit().putLong(KEY_INACTIVITY_AT, inactAt).apply();
		} else if (inactAt <= now) {
			showNotification(app, false);
			inactAt = now + INACTIVITY_DELAY_MS;
			sp.edit().putLong(KEY_INACTIVITY_AT, inactAt).apply();
		}
		scheduleAlarm(app, ACTION_INACTIVITY, REQ_INACTIVITY, inactAt);
	}

	public static void showNotification(Context ctx, boolean isWelcome) {
		Context app = ctx.getApplicationContext();
		ensureChannel(app);
		SharedPreferences sp = app.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
		if (isWelcome) {
			if (sp.getBoolean(KEY_WELCOME_SHOWN, false)) {
				return;
			}
			sp.edit().putBoolean(KEY_WELCOME_SHOWN, true).apply();
		}

		if (Build.VERSION.SDK_INT >= 33) {
			if (app.checkSelfPermission("android.permission.POST_NOTIFICATIONS") != PackageManager.PERMISSION_GRANTED) {
				return;
			}
		}

		NotificationManager nm = (NotificationManager) app.getSystemService(Context.NOTIFICATION_SERVICE);
		if (nm == null) {
			return;
		}

		String lang = getLangCode(app);
		String title = getTitle(lang, isWelcome);
		String body = getBody(lang, isWelcome);

		Intent launch = app.getPackageManager().getLaunchIntentForPackage(app.getPackageName());
		if (launch == null) {
			launch = new Intent(app, GodotApp.class);
		}
		launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
		PendingIntent contentPi = PendingIntent.getActivity(
			app,
			isWelcome ? REQ_WELCOME : REQ_INACTIVITY,
			launch,
			PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
		);

		int iconId = app.getResources().getIdentifier("ic_abtal_notif", "drawable", app.getPackageName());
		if (iconId == 0) {
			iconId = android.R.drawable.ic_popup_reminder;
		}

		Notification.Builder nb = (Build.VERSION.SDK_INT >= 26)
			? new Notification.Builder(app, CHANNEL_ID)
			: new Notification.Builder(app);

		nb.setSmallIcon(iconId)
			.setContentTitle(title)
			.setContentText(body)
			.setStyle(new Notification.BigTextStyle().bigText(body))
			.setAutoCancel(true)
			.setColor(0xFFE87A14)
			.setContentIntent(contentPi);

		nm.notify(isWelcome ? NOTIF_ID_WELCOME : NOTIF_ID_INACTIVITY, nb.build());
	}

	private static void scheduleAlarm(Context ctx, String action, int reqCode, long triggerAtMs) {
		AlarmManager am = (AlarmManager) ctx.getSystemService(Context.ALARM_SERVICE);
		if (am == null) {
			return;
		}
		Intent it = new Intent(ctx, AbtalNotificationReceiver.class);
		it.setAction(action);
		PendingIntent pi = PendingIntent.getBroadcast(
			ctx, reqCode, it,
			PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
		);
		am.cancel(pi);
		try {
			am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMs, pi);
		} catch (Exception e) {
			am.set(AlarmManager.RTC_WAKEUP, triggerAtMs, pi);
		}
	}

	private static String normalizeSupportedLang(String raw) {
		if (raw == null || raw.isEmpty()) {
			return "";
		}
		String c = raw.toLowerCase(Locale.ROOT);
		if (c.startsWith("ar")) return "ar";
		if (c.startsWith("en")) return "en";
		if (c.startsWith("fr")) return "fr";
		if (c.startsWith("de")) return "de";
		if (c.startsWith("it")) return "it";
		if (c.startsWith("es")) return "es";
		if (c.startsWith("tr")) return "tr";
		if (c.startsWith("zh")) return "zh";
		return "";
	}

	private static String getLangCode(Context ctx) {
		String saved = "";
		String lastOs = "";
		if (ctx != null) {
			File cfg = new File(ctx.getFilesDir(), "abtal_progress.cfg");
			if (cfg.exists()) {
				try (BufferedReader br = new BufferedReader(new InputStreamReader(new FileInputStream(cfg), StandardCharsets.UTF_8))) {
					String line;
					while ((line = br.readLine()) != null) {
						String trimmed = line.trim();
						if (trimmed.startsWith("selected_language=")) {
							String val = trimmed.substring("selected_language=".length()).replace("\"", "").trim();
							saved = normalizeSupportedLang(val);
						} else if (trimmed.startsWith("last_os_language=")) {
							lastOs = trimmed.substring("last_os_language=".length()).replace("\"", "").trim().toLowerCase(Locale.ROOT);
						}
					}
				} catch (Exception e) {
					Log.w(TAG, "readSavedGameLanguage error: " + e.getMessage());
				}
			}
		}
		String curOs = Locale.getDefault().getLanguage().toLowerCase(Locale.ROOT);
		boolean osUnchanged = lastOs.isEmpty() || curOs.equals(lastOs);
		if (!saved.isEmpty() && osUnchanged) {
			return saved;
		}
		String osNorm = normalizeSupportedLang(curOs);
		return osNorm.isEmpty() ? "ar" : osNorm;
	}

	private static String getTitle(String lang, boolean isWelcome) {
		if (isWelcome) {
			switch (lang) {
				case "ar": return "أهلاً بك في عالم أبطال!";
				case "fr": return "Bienvenue dans ABTAL !";
				case "de": return "Willkommen bei ABTAL!";
				case "it": return "Benvenuto in ABTAL!";
				case "es": return "¡Bienvenido a ABTAL!";
				case "tr": return "ABTAL Dünyasına Hoş Geldin!";
				case "zh": return "欢迎来到 ABTAL 英雄世界！";
				default: return "Welcome to ABTAL!";
			}
		}
		switch (lang) {
			case "ar": return "ممالك أبطال في انتظارك!";
			case "fr": return "Vos royaumes vous attendent !";
			case "de": return "Deine Königreiche warten auf dich!";
			case "it": return "I tuoi regni ti aspettano!";
			case "es": return "¡Tus reinos te esperan!";
			case "tr": return "Krallıkların Seni Bekliyor!";
			case "zh": return "你的王国在等着你！";
			default: return "Your Kingdoms Await!";
		}
	}

	private static String getBody(String lang, boolean isWelcome) {
		if (isWelcome) {
			switch (lang) {
				case "ar": return "المغامرة بدأت للتو! اجمع العملات وابنِ الجسور وحرّر الممالك الثلاثين الآن.";
				case "fr": return "L'aventure commence ! Collecte des pièces, bâtis des ponts et libère les 30 royaumes.";
				case "de": return "Das Abenteuer beginnt! Sammle Münzen, baue Brücken und befreie alle 30 Königreiche.";
				case "it": return "L'avventura è iniziata! Raccogli monete, costruisci ponti e libera i 30 regni.";
				case "es": return "¡La aventura comenzó! Recoge monedas, construye puentes y libera los 30 reinos.";
				case "tr": return "Macera yeni başladı! Altın topla, nehir köprüleri kur ve 30 krallığı fethet.";
				case "zh": return "冒险才刚刚开始！收集金币、搭建过河桥梁，征服全部 30 个王国！";
				default: return "Your adventure just began! Collect coins, build river bridges, and conquer all 30 kingdoms.";
			}
		}
		switch (lang) {
			case "ar": return "لقد افتقدنا بطلك! عُد الآن لإكمال رحلتك بين القلاع وجمع المزيد من العملات.";
			case "fr": return "Ton héros t'attend ! Reviens continuer ton voyage entre les châteaux.";
			case "de": return "Dein Held vermisst dich! Kehre zurück und setze deine Reise fort.";
			case "it": return "Il tuo eroe ti aspetta! Torna a esplorare i castelli e raccogliere monete.";
			case "es": return "¡Tu héroe te espera! Vuelve ahora y continúa la aventura por los castillos.";
			case "tr": return "Kahramanın seni bekliyor! Geri dön, kaleleri keşfet ve daha fazla altın topla.";
			case "zh": return "你的英雄很想念你！快回来搭建桥梁、击败怪物并解锁下一座城堡吧。";
			default: return "Your hero misses you! Jump back in, gather blocks & coins, and unlock the next castle.";
		}
	}
}
