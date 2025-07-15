import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:gopeed/app/views/fluent/base_pane_body.dart';

import '../../../views/responsive_builder.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isNarrow = ResponsiveBuilder.isNarrow(context);
    final theme = FluentTheme.of(context);

    return BasePaneBody.scrollable(
      title: 'login'.tr,
      children: [
        Center(
          child: Container(
            decoration: ShapeDecoration(
              color: theme.resources.cardBackgroundFillColorDefault,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: theme.resources.cardStrokeColorDefault),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6.0), bottom: Radius.circular(6.0)),
              ),
            ),
            constraints: BoxConstraints(maxWidth: isNarrow ? double.infinity : 420),
            padding: EdgeInsets.all(isNarrow ? 24.0 : 40.0),
            child: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Form(
                key: controller.formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo/Title Section
                    Container(
                      alignment: Alignment.center,
                      margin: EdgeInsets.only(bottom: isNarrow ? 32 : 48),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isNarrow ? 8 : 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(isNarrow ? 20 : 24),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.accentColor.withValues(alpha: 0.2),
                                  blurRadius: isNarrow ? 16 : 24,
                                  offset: Offset(0, isNarrow ? 8 : 12),
                                  spreadRadius: isNarrow ? 1 : 2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(isNarrow ? 16 : 20),
                              child: SvgPicture.asset(
                                'assets/icon/icon.svg',
                                width: isNarrow ? 56 : 72,
                                height: isNarrow ? 56 : 72,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gopeed',
                            style: Get.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Get.theme.colorScheme.onSurface,
                              letterSpacing: 2.0,
                              fontSize: isNarrow ? 28 : 36,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Username Field
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(1.0),
                      child: InfoLabel(
                        label: 'username'.tr,
                        child: TextFormBox(
                          controller: controller.usernameController,
                          autofillHints: const [AutofillHints.username],
                          autofocus: true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => controller.login(context),
                          prefix: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(FluentIcons.person_24_regular, size: 24.0, color: theme.accentColor),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'username_required'.tr;
                            }
                            return null;
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: isNarrow ? 16 : 24),

                    // Password Field
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(2.0),
                      child: Obx(
                        () => InfoLabel(
                          label: 'password'.tr,
                          child: TextFormBox(
                            controller: controller.passwordController,
                            autofillHints: const [AutofillHints.password],
                            obscureText: !controller.passwordVisible.value,
                            prefix: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(FluentIcons.password_24_regular, size: 24.0, color: theme.accentColor),
                            ),
                            suffix: IconButton(
                              icon: Icon(
                                controller.passwordVisible.value
                                    ? FluentIcons.eye_off_20_regular
                                    : FluentIcons.eye_20_regular,
                                color: theme.resources.textFillColorSecondary,
                                size: 20.0,
                              ),
                              onPressed: controller.togglePasswordVisibility,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'password_required'.tr;
                              }
                              return null;
                            },
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => controller.login(context),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: isNarrow ? 24 : 32),

                    // Login Button
                    Obx(
                      () => FilledButton(
                        onPressed: controller.isLoading.value ? null : () => controller.login(context),
                        child: controller.isLoading.value
                            ? const SizedBox(height: 24, width: 24, child: ProgressRing(strokeWidth: 2.5))
                            : Text(
                                'login'.tr,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
