#!/sbin/sh
# 
# /system/addon.d/70-gapps.sh
#
. /tmp/backuptool.functions

list_files() {
cat <<EOF
app/ChromeBookmarksSyncAdapter.apk
app/GoogleCalendarSyncAdapter.apk
app/GoogleContactsSyncAdapter.apk
etc/g.prop
etc/permissions/com.google.android.ble.xml
etc/permissions/com.google.android.camera2.xml
etc/permissions/com.google.android.maps.xml
etc/permissions/com.google.android.media.effects.xml
etc/permissions/com.google.widevine.software.drm.xml
etc/permissions/features.xml
etc/preferred-apps/google.xml
framework/com.google.android.ble.jar
framework/com.google.android.camera2.jar
framework/com.google.android.maps.jar
framework/com.google.android.media.effects.jar
framework/com.google.widevine.software.drm.jar
lib/libAppDataSearch.so
lib/libconscrypt_gmscore_jni.so
lib/libgames_rtmp_jni.so
lib/libgcastv2_base.so
lib/libgcastv2_support.so
lib/libgmscore.so
lib/libgms-ocrclient.so
lib/libjgcastservice.so
lib/libjni_latinime.so
lib/libWhisper.so
priv-app/GoogleBackupTransport.apk
priv-app/GoogleFeedback.apk
priv-app/GoogleLoginService.apk
priv-app/GoogleOneTimeInitializer.apk
priv-app/GooglePartnerSetup.apk
priv-app/GoogleServicesFramework.apk
priv-app/Phonesky.apk
priv-app/PrebuiltGmsCore.apk
priv-app/SetupWizard.apk
EOF
}

# Backup/Restore using /sdcard if the installed GApps size plus a buffer for other addon.d backups (204800=200MB) is larger than /tmp
installed_gapps_size_kb=$(grep "^installed_gapps_size_kb" /tmp/gapps.prop | cut -d= -f2)
if [ ! "$installed_gapps_size_kb" ]; then
  installed_gapps_size_kb=$(cd /system; du -ak `list_files` | awk '{ i+=$1 } END { print i }')
  echo "installed_gapps_size_kb=$installed_gapps_size_kb" >> /tmp/gapps.prop
fi

free_tmp_size_kb=$(grep "^free_tmp_size_kb" /tmp/gapps.prop | cut -d= -f2)
if [ ! "$free_tmp_size_kb" ]; then
  free_tmp_size_kb=$(df -k /tmp | tail -n 1 | awk '{ print $4 }')
  echo "free_tmp_size_kb=$free_tmp_size_kb" >> /tmp/gapps.prop
fi

buffer_size_kb=204800
if [ $((installed_gapps_size_kb + buffer_size_kb)) -ge $free_tmp_size_kb ]; then
  C=/sdcard/tmp-gapps
fi

case "$1" in
  backup)
    list_files | while read FILE DUMMY; do
      backup_file $S/$FILE
    done
  ;;
  restore)
    list_files | while read FILE REPLACEMENT; do
      R=""
      [ -n "$REPLACEMENT" ] && R="$S/$REPLACEMENT"
      [ -f "$C/$S/$FILE" ] && restore_file $S/$FILE $R
    done
  ;;
  pre-backup)
    # Stub
  ;;
  post-backup)
    # Stub
  ;;
  pre-restore)
    # Additional ROM/AOSP Removals from GApps Remover

    # Removing pieces that may be left over from other GApps or ROM's (from updater-script)
    rm -f /system/app/BrowserProviderProxy.apk
    rm -f /system/app/GmsCore.apk
    rm -f /system/app/PartnerBookmarksProvider.apk
    rm -f /system/app/QuickSearchBox.apk
    rm -f /system/app/Vending.apk
    rm -f /system/priv-app/Calendar.apk
    rm -f /system/priv-app/GmsCore.apk
    rm -f /system/priv-app/GoogleSearch.apk
    rm -f /system/priv-app/OneTimeInitializer.apk
    rm -f /system/priv-app/QuickSearchBox.apk
    rm -f /system/priv-app/Vending.apk

    # Remove apps from 'app' that need to be installed in 'priv-app' (from updater-script)
    rm -f /system/app/CalendarProvider.apk
    rm -f /system/app/GoogleBackupTransport.apk
    rm -f /system/app/GoogleFeedback.apk
    rm -f /system/app/GoogleLoginService.apk
    rm -f /system/app/GoogleOneTimeInitializer.apk
    rm -f /system/app/GooglePartnerSetup.apk
    rm -f /system/app/GoogleServicesFramework.apk
    rm -f /system/app/OneTimeInitializer.apk
    rm -f /system/app/Phonesky.apk
    rm -f /system/app/PrebuiltGmsCore.apk
    rm -f /system/app/SetupWizard.apk
    rm -f /system/app/Velvet.apk
  ;;
  post-restore)
    # Fix ownership/permissions and clean up after backup and restore from /sdcard
    for i in `list_files`; do
      busybox chown root.root /system/$i
      busybox chmod 644 /system/$i
      busybox chmod 755 `busybox dirname /system/$i`
    done
    rm -rf /sdcard/tmp-gapps
  ;;
esac
