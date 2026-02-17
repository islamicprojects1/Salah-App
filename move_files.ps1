$base = "c:\development\Salah-App\lib"

# ============================================================
# MOVE FILES TO FEATURE-FIRST STRUCTURE
# ============================================================

$moves = @(
    # === AUTH FEATURE ===
    @("controller\auth_controller.dart", "features\auth\controller\auth_controller.dart"),
    @("core\services\auth_service.dart", "features\auth\data\services\auth_service.dart"),
    @("data\models\user_model.dart", "features\auth\data\models\user_model.dart"),
    @("data\models\user_privacy_settings.dart", "features\auth\data\models\user_privacy_settings.dart"),
    @("data\repositories\user_repository.dart", "features\auth\data\repositories\user_repository.dart"),
    @("controller\bindings\auth_binding.dart", "features\auth\presentation\bindings\auth_binding.dart"),
    @("view\screens\auth\login_screen.dart", "features\auth\presentation\screens\login_screen.dart"),
    @("view\screens\auth\register_screen.dart", "features\auth\presentation\screens\register_screen.dart"),
    @("view\screens\auth\profile_setup_screen.dart", "features\auth\presentation\screens\profile_setup_screen.dart"),

    # === PRAYER FEATURE ===
    @("controller\dashboard_controller.dart", "features\prayer\controller\dashboard_controller.dart"),
    @("controller\missed_prayers_controller.dart", "features\prayer\controller\missed_prayers_controller.dart"),
    @("controller\qibla_controller.dart", "features\prayer\controller\qibla_controller.dart"),
    @("data\models\prayer_log_model.dart", "features\prayer\data\models\prayer_log_model.dart"),
    @("data\models\prayer_time_model.dart", "features\prayer\data\models\prayer_time_model.dart"),
    @("data\models\live_context_models.dart", "features\prayer\data\models\live_context_models.dart"),
    @("data\sync\sync_queue_models.dart", "features\prayer\data\models\sync_queue_models.dart"),
    @("data\repositories\prayer_repository.dart", "features\prayer\data\repositories\prayer_repository.dart"),
    @("core\services\prayer_time_service.dart", "features\prayer\data\services\prayer_time_service.dart"),
    @("core\services\notification_service.dart", "features\prayer\data\services\notification_service.dart"),
    @("core\services\smart_notification_service.dart", "features\prayer\data\services\smart_notification_service.dart"),
    @("core\services\qada_detection_service.dart", "features\prayer\data\services\qada_detection_service.dart"),
    @("core\services\live_context_service.dart", "features\prayer\data\services\live_context_service.dart"),
    @("core\services\firestore_service.dart", "features\prayer\data\services\firestore_service.dart"),
    @("controller\bindings\dashboard_binding.dart", "features\prayer\presentation\bindings\dashboard_binding.dart"),
    @("view\screens\dashboard\dashboard_screen.dart", "features\prayer\presentation\screens\dashboard_screen.dart"),
    @("view\screens\missed_prayers\missed_prayers_screen.dart", "features\prayer\presentation\screens\missed_prayers_screen.dart"),
    @("view\screens\qibla\qibla_screen.dart", "features\prayer\presentation\screens\qibla_screen.dart"),
    @("view\screens\home\home_screen.dart", "features\prayer\presentation\screens\home_screen.dart"),
    @("view\widgets\smart_prayer_circle.dart", "features\prayer\presentation\widgets\smart_prayer_circle.dart"),
    @("view\widgets\countdown_circle.dart", "features\prayer\presentation\widgets\countdown_circle.dart"),
    @("view\widgets\prayer_card.dart", "features\prayer\presentation\widgets\prayer_card.dart"),
    @("view\widgets\prayer_heatmap.dart", "features\prayer\presentation\widgets\prayer_heatmap.dart"),
    @("view\widgets\prayer_timeline.dart", "features\prayer\presentation\widgets\prayer_timeline.dart"),
    @("view\widgets\daily_review_card.dart", "features\prayer\presentation\widgets\daily_review_card.dart"),
    @("view\widgets\missed_prayer_card.dart", "features\prayer\presentation\widgets\missed_prayer_card.dart"),
    @("view\widgets\qada_review_bottom_sheet.dart", "features\prayer\presentation\widgets\qada_review_bottom_sheet.dart"),
    @("view\widgets\drawer.dart", "features\prayer\presentation\widgets\drawer.dart"),

    # === FAMILY FEATURE ===
    @("controller\family_controller.dart", "features\family\controller\family_controller.dart"),
    @("data\models\family_model.dart", "features\family\data\models\family_model.dart"),
    @("data\models\family_activity_model.dart", "features\family\data\models\family_activity_model.dart"),
    @("data\models\family_pulse_model.dart", "features\family\data\models\family_pulse_model.dart"),
    @("data\models\group_model.dart", "features\family\data\models\group_model.dart"),
    @("data\models\challenge_model.dart", "features\family\data\models\challenge_model.dart"),
    @("data\models\feed_item_model.dart", "features\family\data\models\feed_item_model.dart"),
    @("data\repositories\family_repository.dart", "features\family\data\repositories\family_repository.dart"),
    @("data\repositories\achievement_repository.dart", "features\family\data\repositories\achievement_repository.dart"),
    @("core\services\family_service.dart", "features\family\data\services\family_service.dart"),
    @("controller\bindings\family_binding.dart", "features\family\presentation\bindings\family_binding.dart"),
    @("view\screens\family\family_dashboard_screen.dart", "features\family\presentation\screens\family_dashboard_screen.dart"),
    @("view\screens\family\create_family_screen.dart", "features\family\presentation\screens\create_family_screen.dart"),
    @("view\screens\family\join_family_screen.dart", "features\family\presentation\screens\join_family_screen.dart"),
    @("view\widgets\family_vitality_orb.dart", "features\family\presentation\widgets\family_vitality_orb.dart"),
    @("view\widgets\family_flame_widget.dart", "features\family\presentation\widgets\family_flame_widget.dart"),
    @("view\widgets\synchronicity_avatar.dart", "features\family\presentation\widgets\synchronicity_avatar.dart"),
    @("view\widgets\member_card.dart", "features\family\presentation\widgets\member_card.dart"),

    # === SETTINGS FEATURE ===
    @("controller\settings\settings_controller.dart", "features\settings\controller\settings_controller.dart"),
    @("controller\settings\selected_city_controller.dart", "features\settings\controller\selected_city_controller.dart"),
    @("core\services\theme_service.dart", "features\settings\data\services\theme_service.dart"),
    @("core\services\localization_service.dart", "features\settings\data\services\localization_service.dart"),
    @("controller\bindings\settings\settings_binding.dart", "features\settings\presentation\bindings\settings_binding.dart"),
    @("controller\bindings\settings\selected_city_binding.dart", "features\settings\presentation\bindings\selected_city_binding.dart"),
    @("view\screens\settings\settings_screen.dart", "features\settings\presentation\screens\settings_screen.dart"),
    @("view\screens\settings\select_city_screen.dart", "features\settings\presentation\screens\select_city_screen.dart"),
    @("view\screens\settings\prayer_adjustment_screen.dart", "features\settings\presentation\screens\prayer_adjustment_screen.dart"),
    @("view\screens\settings\privacy_settings_screen.dart", "features\settings\presentation\screens\privacy_settings_screen.dart"),

    # === NOTIFICATIONS FEATURE ===
    @("controller\notifications_controller.dart", "features\notifications\controller\notifications_controller.dart"),
    @("data\models\notification_models.dart", "features\notifications\data\models\notification_models.dart"),
    @("core\services\fcm_service.dart", "features\notifications\data\services\fcm_service.dart"),
    @("view\screens\notifications\notifications_screen.dart", "features\notifications\presentation\screens\notifications_screen.dart"),

    # === ONBOARDING FEATURE ===
    @("controller\onboarding_controller.dart", "features\onboarding\controller\onboarding_controller.dart"),
    @("view\screens\onboarding\onboarding_screen.dart", "features\onboarding\presentation\screens\onboarding_screen.dart"),
    @("view\screens\onboarding\welcome_page.dart", "features\onboarding\presentation\screens\welcome_page.dart"),
    @("view\screens\onboarding\features_page.dart", "features\onboarding\presentation\screens\features_page.dart"),
    @("view\screens\onboarding\permissions_page.dart", "features\onboarding\presentation\screens\permissions_page.dart"),
    @("view\screens\onboarding\profile_setup_page.dart", "features\onboarding\presentation\screens\profile_setup_page.dart"),

    # === PROFILE FEATURE ===
    @("controller\profile_controller.dart", "features\profile\controller\profile_controller.dart"),
    @("view\screens\profile\profile_screen.dart", "features\profile\presentation\screens\profile_screen.dart"),

    # === SPLASH ===
    @("view\screens\splash\splash_screen.dart", "features\splash\presentation\screens\splash_screen.dart"),

    # === SHARED ===
    @("data\models\achievement_model.dart", "shared\data\models\achievement_model.dart"),
    @("data\models\admin_models.dart", "shared\data\models\admin_models.dart"),
    @("data\repositories\base_repository.dart", "shared\data\repositories\base_repository.dart"),

    # === CORE WIDGETS (shared widgets) ===
    @("view\widgets\app_button.dart", "core\widgets\app_button.dart"),
    @("view\widgets\app_dialog.dart", "core\widgets\app_dialog.dart"),
    @("view\widgets\app_dialogs.dart", "core\widgets\app_dialogs.dart"),
    @("view\widgets\app_loading.dart", "core\widgets\app_loading.dart"),
    @("view\widgets\app_text_field.dart", "core\widgets\app_text_field.dart"),
    @("view\widgets\connection_status_indicator.dart", "core\widgets\connection_status_indicator.dart"),
    @("view\widgets\empty_state.dart", "core\widgets\empty_state.dart"),
    @("view\widgets\widgets.dart", "core\widgets\widgets.dart")
)

$moved = 0
$errors = 0
foreach ($m in $moves) {
    $src = Join-Path $base $m[0]
    $dst = Join-Path $base $m[1]
    if (Test-Path $src) {
        Move-Item -Path $src -Destination $dst -Force
        $moved++
    } else {
        Write-Host "SKIP (not found): $($m[0])"
        $errors++
    }
}

Write-Host ""
Write-Host "Done! Moved: $moved files, Skipped: $errors files"
