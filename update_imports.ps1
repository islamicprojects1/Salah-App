$base = "c:\development\Salah-App\lib"

# Map of old import paths to new import paths
$replacements = @{
    # === AUTH ===
    "package:salah/controller/auth_controller.dart" = "package:salah/features/auth/controller/auth_controller.dart"
    "package:salah/core/services/auth_service.dart" = "package:salah/features/auth/data/services/auth_service.dart"
    "package:salah/data/models/user_model.dart" = "package:salah/features/auth/data/models/user_model.dart"
    "package:salah/data/models/user_privacy_settings.dart" = "package:salah/features/auth/data/models/user_privacy_settings.dart"
    "package:salah/data/repositories/user_repository.dart" = "package:salah/features/auth/data/repositories/user_repository.dart"
    "package:salah/controller/bindings/auth_binding.dart" = "package:salah/features/auth/presentation/bindings/auth_binding.dart"
    "package:salah/view/screens/auth/login_screen.dart" = "package:salah/features/auth/presentation/screens/login_screen.dart"
    "package:salah/view/screens/auth/register_screen.dart" = "package:salah/features/auth/presentation/screens/register_screen.dart"
    "package:salah/view/screens/auth/profile_setup_screen.dart" = "package:salah/features/auth/presentation/screens/profile_setup_screen.dart"

    # === PRAYER ===
    "package:salah/controller/dashboard_controller.dart" = "package:salah/features/prayer/controller/dashboard_controller.dart"
    "package:salah/controller/missed_prayers_controller.dart" = "package:salah/features/prayer/controller/missed_prayers_controller.dart"
    "package:salah/controller/qibla_controller.dart" = "package:salah/features/prayer/controller/qibla_controller.dart"
    "package:salah/data/models/prayer_log_model.dart" = "package:salah/features/prayer/data/models/prayer_log_model.dart"
    "package:salah/data/models/prayer_time_model.dart" = "package:salah/features/prayer/data/models/prayer_time_model.dart"
    "package:salah/data/models/live_context_models.dart" = "package:salah/features/prayer/data/models/live_context_models.dart"
    "package:salah/data/sync/sync_queue_models.dart" = "package:salah/features/prayer/data/models/sync_queue_models.dart"
    "package:salah/data/repositories/prayer_repository.dart" = "package:salah/features/prayer/data/repositories/prayer_repository.dart"
    "package:salah/core/services/prayer_time_service.dart" = "package:salah/features/prayer/data/services/prayer_time_service.dart"
    "package:salah/core/services/notification_service.dart" = "package:salah/features/prayer/data/services/notification_service.dart"
    "package:salah/core/services/smart_notification_service.dart" = "package:salah/features/prayer/data/services/smart_notification_service.dart"
    "package:salah/core/services/qada_detection_service.dart" = "package:salah/features/prayer/data/services/qada_detection_service.dart"
    "package:salah/core/services/live_context_service.dart" = "package:salah/features/prayer/data/services/live_context_service.dart"
    "package:salah/core/services/firestore_service.dart" = "package:salah/features/prayer/data/services/firestore_service.dart"
    "package:salah/controller/bindings/dashboard_binding.dart" = "package:salah/features/prayer/presentation/bindings/dashboard_binding.dart"
    "package:salah/view/screens/dashboard/dashboard_screen.dart" = "package:salah/features/prayer/presentation/screens/dashboard_screen.dart"
    "package:salah/view/screens/missed_prayers/missed_prayers_screen.dart" = "package:salah/features/prayer/presentation/screens/missed_prayers_screen.dart"
    "package:salah/view/screens/qibla/qibla_screen.dart" = "package:salah/features/prayer/presentation/screens/qibla_screen.dart"
    "package:salah/view/screens/home/home_screen.dart" = "package:salah/features/prayer/presentation/screens/home_screen.dart"
    "package:salah/view/widgets/smart_prayer_circle.dart" = "package:salah/features/prayer/presentation/widgets/smart_prayer_circle.dart"
    "package:salah/view/widgets/countdown_circle.dart" = "package:salah/features/prayer/presentation/widgets/countdown_circle.dart"
    "package:salah/view/widgets/prayer_card.dart" = "package:salah/features/prayer/presentation/widgets/prayer_card.dart"
    "package:salah/view/widgets/prayer_heatmap.dart" = "package:salah/features/prayer/presentation/widgets/prayer_heatmap.dart"
    "package:salah/view/widgets/prayer_timeline.dart" = "package:salah/features/prayer/presentation/widgets/prayer_timeline.dart"
    "package:salah/view/widgets/daily_review_card.dart" = "package:salah/features/prayer/presentation/widgets/daily_review_card.dart"
    "package:salah/view/widgets/missed_prayer_card.dart" = "package:salah/features/prayer/presentation/widgets/missed_prayer_card.dart"
    "package:salah/view/widgets/qada_review_bottom_sheet.dart" = "package:salah/features/prayer/presentation/widgets/qada_review_bottom_sheet.dart"
    "package:salah/view/widgets/drawer.dart" = "package:salah/features/prayer/presentation/widgets/drawer.dart"

    # === FAMILY ===
    "package:salah/controller/family_controller.dart" = "package:salah/features/family/controller/family_controller.dart"
    "package:salah/data/models/family_model.dart" = "package:salah/features/family/data/models/family_model.dart"
    "package:salah/data/models/family_activity_model.dart" = "package:salah/features/family/data/models/family_activity_model.dart"
    "package:salah/data/models/family_pulse_model.dart" = "package:salah/features/family/data/models/family_pulse_model.dart"
    "package:salah/data/models/group_model.dart" = "package:salah/features/family/data/models/group_model.dart"
    "package:salah/data/models/challenge_model.dart" = "package:salah/features/family/data/models/challenge_model.dart"
    "package:salah/data/models/feed_item_model.dart" = "package:salah/features/family/data/models/feed_item_model.dart"
    "package:salah/data/repositories/family_repository.dart" = "package:salah/features/family/data/repositories/family_repository.dart"
    "package:salah/data/repositories/achievement_repository.dart" = "package:salah/features/family/data/repositories/achievement_repository.dart"
    "package:salah/core/services/family_service.dart" = "package:salah/features/family/data/services/family_service.dart"
    "package:salah/controller/bindings/family_binding.dart" = "package:salah/features/family/presentation/bindings/family_binding.dart"
    "package:salah/view/screens/family/family_dashboard_screen.dart" = "package:salah/features/family/presentation/screens/family_dashboard_screen.dart"
    "package:salah/view/screens/family/create_family_screen.dart" = "package:salah/features/family/presentation/screens/create_family_screen.dart"
    "package:salah/view/screens/family/join_family_screen.dart" = "package:salah/features/family/presentation/screens/join_family_screen.dart"
    "package:salah/view/widgets/family_vitality_orb.dart" = "package:salah/features/family/presentation/widgets/family_vitality_orb.dart"
    "package:salah/view/widgets/family_flame_widget.dart" = "package:salah/features/family/presentation/widgets/family_flame_widget.dart"
    "package:salah/view/widgets/synchronicity_avatar.dart" = "package:salah/features/family/presentation/widgets/synchronicity_avatar.dart"
    "package:salah/view/widgets/member_card.dart" = "package:salah/features/family/presentation/widgets/member_card.dart"

    # === SETTINGS ===
    "package:salah/controller/settings/settings_controller.dart" = "package:salah/features/settings/controller/settings_controller.dart"
    "package:salah/controller/settings/selected_city_controller.dart" = "package:salah/features/settings/controller/selected_city_controller.dart"
    "package:salah/core/services/theme_service.dart" = "package:salah/features/settings/data/services/theme_service.dart"
    "package:salah/core/services/localization_service.dart" = "package:salah/features/settings/data/services/localization_service.dart"
    "package:salah/controller/bindings/settings/settings_binding.dart" = "package:salah/features/settings/presentation/bindings/settings_binding.dart"
    "package:salah/controller/bindings/settings/selected_city_binding.dart" = "package:salah/features/settings/presentation/bindings/selected_city_binding.dart"
    "package:salah/view/screens/settings/settings_screen.dart" = "package:salah/features/settings/presentation/screens/settings_screen.dart"
    "package:salah/view/screens/settings/select_city_screen.dart" = "package:salah/features/settings/presentation/screens/select_city_screen.dart"
    "package:salah/view/screens/settings/prayer_adjustment_screen.dart" = "package:salah/features/settings/presentation/screens/prayer_adjustment_screen.dart"
    "package:salah/view/screens/settings/privacy_settings_screen.dart" = "package:salah/features/settings/presentation/screens/privacy_settings_screen.dart"

    # === NOTIFICATIONS ===
    "package:salah/controller/notifications_controller.dart" = "package:salah/features/notifications/controller/notifications_controller.dart"
    "package:salah/data/models/notification_models.dart" = "package:salah/features/notifications/data/models/notification_models.dart"
    "package:salah/core/services/fcm_service.dart" = "package:salah/features/notifications/data/services/fcm_service.dart"
    "package:salah/view/screens/notifications/notifications_screen.dart" = "package:salah/features/notifications/presentation/screens/notifications_screen.dart"

    # === ONBOARDING ===
    "package:salah/controller/onboarding_controller.dart" = "package:salah/features/onboarding/controller/onboarding_controller.dart"
    "package:salah/view/screens/onboarding/onboarding_screen.dart" = "package:salah/features/onboarding/presentation/screens/onboarding_screen.dart"

    # === PROFILE ===
    "package:salah/controller/profile_controller.dart" = "package:salah/features/profile/controller/profile_controller.dart"
    "package:salah/view/screens/profile/profile_screen.dart" = "package:salah/features/profile/presentation/screens/profile_screen.dart"

    # === SPLASH ===
    "package:salah/view/screens/splash/splash_screen.dart" = "package:salah/features/splash/presentation/screens/splash_screen.dart"

    # === SHARED ===
    "package:salah/data/models/achievement_model.dart" = "package:salah/shared/data/models/achievement_model.dart"
    "package:salah/data/models/admin_models.dart" = "package:salah/shared/data/models/admin_models.dart"
    "package:salah/data/repositories/base_repository.dart" = "package:salah/shared/data/repositories/base_repository.dart"

    # === CORE WIDGETS ===
    "package:salah/view/widgets/app_button.dart" = "package:salah/core/widgets/app_button.dart"
    "package:salah/view/widgets/app_dialog.dart" = "package:salah/core/widgets/app_dialog.dart"
    "package:salah/view/widgets/app_dialogs.dart" = "package:salah/core/widgets/app_dialogs.dart"
    "package:salah/view/widgets/app_loading.dart" = "package:salah/core/widgets/app_loading.dart"
    "package:salah/view/widgets/app_text_field.dart" = "package:salah/core/widgets/app_text_field.dart"
    "package:salah/view/widgets/connection_status_indicator.dart" = "package:salah/core/widgets/connection_status_indicator.dart"
    "package:salah/view/widgets/empty_state.dart" = "package:salah/core/widgets/empty_state.dart"
    "package:salah/view/widgets/widgets.dart" = "package:salah/core/widgets/widgets.dart"
}

# Get all .dart files
$files = Get-ChildItem -Path $base -Filter "*.dart" -Recurse

$totalReplacements = 0
foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    if ($null -eq $content) { continue }
    
    $modified = $false
    foreach ($old in $replacements.Keys) {
        if ($content.Contains($old)) {
            $content = $content.Replace($old, $replacements[$old])
            $modified = $true
            $totalReplacements++
        }
    }
    
    if ($modified) {
        Set-Content -Path $file.FullName -Value $content -NoNewline -Encoding UTF8
        Write-Host "Updated: $($file.FullName.Replace($base, ''))"
    }
}

Write-Host ""
Write-Host "Total import replacements: $totalReplacements"
