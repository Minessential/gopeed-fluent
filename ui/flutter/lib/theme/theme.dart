import 'package:fluent_ui/fluent_ui.dart';

class GopeedTheme {
  static const _gopeedreenPrimaryValue = 0xFF79C476;

  static const _gopeedreenAccentValue = 0xFFC9FFC7;

  static final buttonTheme = ButtonThemeData(
    defaultButtonStyle: ButtonStyle(
      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
    ),
    filledButtonStyle: ButtonStyle(
      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
    ),
  );

  static final _light = FluentThemeData(
    brightness: Brightness.light,
    accentColor: const Color(_gopeedreenPrimaryValue).toAccentColor(),
    resources: const ResourceDictionary.light().copyWith(systemFillColorAttentionBackground: const Color(0xFFf3f3f3)),
    buttonTheme: buttonTheme,
  );
  static final light = _light;

  static final _dark = FluentThemeData(
    brightness: Brightness.dark,
    accentColor: const Color(_gopeedreenAccentValue).toAccentColor(),
    resources: const ResourceDictionary.dark().copyWith(systemFillColorAttentionBackground: const Color(0xFF202020)),
    buttonTheme: buttonTheme,
  );
  static final dark = _dark;
}


/// 获取卡片背景颜色
WidgetStateProperty<Color> getCardBackgroundColor(FluentThemeData theme) {
  return WidgetStateProperty.resolveWith<Color>((states) {
    final color = theme.resources.cardBackgroundFillColorDefault;
    if (states.contains(WidgetState.hovered)) {
      return color.withValues(alpha: 0.1);
    }
    if (states.contains(WidgetState.pressed)) {
      return color.withValues(alpha: 0.2);
    }
    return color;
  });
}

extension ResourceDictionaryExt on ResourceDictionary {
  /// Copy the current [ResourceDictionary] with the provided values.
  /// can access by `FluentTheme.of(context).resources.copyWith(...)`
  ResourceDictionary copyWith({
    Color? textFillColorPrimary,
    Color? textFillColorSecondary,
    Color? textFillColorTertiary,
    Color? textFillColorDisabled,
    Color? textFillColorInverse,
    Color? accentTextFillColorDisabled,
    Color? textOnAccentFillColorSelectedText,
    Color? textOnAccentFillColorPrimary,
    Color? textOnAccentFillColorSecondary,
    Color? textOnAccentFillColorDisabled,
    Color? controlFillColorDefault,
    Color? controlFillColorSecondary,
    Color? controlFillColorTertiary,
    Color? controlFillColorDisabled,
    Color? controlFillColorTransparent,
    Color? controlFillColorInputActive,
    Color? controlStrongFillColorDefault,
    Color? controlStrongFillColorDisabled,
    Color? controlSolidFillColorDefault,
    Color? subtleFillColorTransparent,
    Color? subtleFillColorSecondary,
    Color? subtleFillColorTertiary,
    Color? subtleFillColorDisabled,
    Color? controlAltFillColorTransparent,
    Color? controlAltFillColorSecondary,
    Color? controlAltFillColorTertiary,
    Color? controlAltFillColorQuarternary,
    Color? controlAltFillColorDisabled,
    Color? controlOnImageFillColorDefault,
    Color? controlOnImageFillColorSecondary,
    Color? controlOnImageFillColorTertiary,
    Color? controlOnImageFillColorDisabled,
    Color? accentFillColorDisabled,
    Color? controlStrokeColorDefault,
    Color? controlStrokeColorSecondary,
    Color? controlStrokeColorOnAccentDefault,
    Color? controlStrokeColorOnAccentSecondary,
    Color? controlStrokeColorOnAccentTertiary,
    Color? controlStrokeColorOnAccentDisabled,
    Color? controlStrokeColorForStrongFillWhenOnImage,
    Color? cardStrokeColorDefault,
    Color? cardStrokeColorDefaultSolid,
    Color? controlStrongStrokeColorDefault,
    Color? controlStrongStrokeColorDisabled,
    Color? surfaceStrokeColorDefault,
    Color? surfaceStrokeColorFlyout,
    Color? surfaceStrokeColorInverse,
    Color? dividerStrokeColorDefault,
    Color? focusStrokeColorOuter,
    Color? focusStrokeColorInner,
    Color? cardBackgroundFillColorDefault,
    Color? cardBackgroundFillColorSecondary,
    Color? smokeFillColorDefault,
    Color? layerFillColorDefault,
    Color? layerFillColorAlt,
    Color? layerOnAcrylicFillColorDefault,
    Color? layerOnAccentAcrylicFillColorDefault,
    Color? layerOnMicaBaseAltFillColorDefault,
    Color? layerOnMicaBaseAltFillColorSecondary,
    Color? layerOnMicaBaseAltFillColorTertiary,
    Color? layerOnMicaBaseAltFillColorTransparent,
    Color? solidBackgroundFillColorBase,
    Color? solidBackgroundFillColorSecondary,
    Color? solidBackgroundFillColorTertiary,
    Color? solidBackgroundFillColorQuarternary,
    Color? solidBackgroundFillColorTransparent,
    Color? solidBackgroundFillColorBaseAlt,
    Color? systemFillColorSuccess,
    Color? systemFillColorCaution,
    Color? systemFillColorCritical,
    Color? systemFillColorNeutral,
    Color? systemFillColorSolidNeutral,
    Color? systemFillColorAttentionBackground,
    Color? systemFillColorSuccessBackground,
    Color? systemFillColorCautionBackground,
    Color? systemFillColorCriticalBackground,
    Color? systemFillColorNeutralBackground,
    Color? systemFillColorSolidAttentionBackground,
    Color? systemFillColorSolidNeutralBackground,
  }) {
    return ResourceDictionary.raw(
      textFillColorPrimary: textFillColorPrimary ?? this.textFillColorPrimary,
      textFillColorSecondary: textFillColorSecondary ?? this.textFillColorSecondary,
      textFillColorTertiary: textFillColorTertiary ?? this.textFillColorTertiary,
      textFillColorDisabled: textFillColorDisabled ?? this.textFillColorDisabled,
      textFillColorInverse: textFillColorInverse ?? this.textFillColorInverse,
      accentTextFillColorDisabled: accentTextFillColorDisabled ?? this.accentTextFillColorDisabled,
      textOnAccentFillColorSelectedText: textOnAccentFillColorSelectedText ?? this.textOnAccentFillColorSelectedText,
      textOnAccentFillColorPrimary: textOnAccentFillColorPrimary ?? this.textOnAccentFillColorPrimary,
      textOnAccentFillColorSecondary: textOnAccentFillColorSecondary ?? this.textOnAccentFillColorSecondary,
      textOnAccentFillColorDisabled: textOnAccentFillColorDisabled ?? this.textOnAccentFillColorDisabled,
      controlFillColorDefault: controlFillColorDefault ?? this.controlFillColorDefault,
      controlFillColorSecondary: controlFillColorSecondary ?? this.controlFillColorSecondary,
      controlFillColorTertiary: controlFillColorTertiary ?? this.controlFillColorTertiary,
      controlFillColorDisabled: controlFillColorDisabled ?? this.controlFillColorDisabled,
      controlFillColorTransparent: controlFillColorTransparent ?? this.controlFillColorTransparent,
      controlFillColorInputActive: controlFillColorInputActive ?? this.controlFillColorInputActive,
      controlStrongFillColorDefault: controlStrongFillColorDefault ?? this.controlStrongFillColorDefault,
      controlStrongFillColorDisabled: controlStrongFillColorDisabled ?? this.controlStrongFillColorDisabled,
      controlSolidFillColorDefault: controlSolidFillColorDefault ?? this.controlSolidFillColorDefault,
      subtleFillColorTransparent: subtleFillColorTransparent ?? this.subtleFillColorTransparent,
      subtleFillColorSecondary: subtleFillColorSecondary ?? this.subtleFillColorSecondary,
      subtleFillColorTertiary: subtleFillColorTertiary ?? this.subtleFillColorTertiary,
      subtleFillColorDisabled: subtleFillColorDisabled ?? this.subtleFillColorDisabled,
      controlAltFillColorTransparent: controlAltFillColorTransparent ?? this.controlAltFillColorTransparent,
      controlAltFillColorSecondary: controlAltFillColorSecondary ?? this.controlAltFillColorSecondary,
      controlAltFillColorTertiary: controlAltFillColorTertiary ?? this.controlAltFillColorTertiary,
      controlAltFillColorQuarternary: controlAltFillColorQuarternary ?? this.controlAltFillColorQuarternary,
      controlAltFillColorDisabled: controlAltFillColorDisabled ?? this.controlAltFillColorDisabled,
      controlOnImageFillColorDefault: controlOnImageFillColorDefault ?? this.controlOnImageFillColorDefault,
      controlOnImageFillColorSecondary: controlOnImageFillColorSecondary ?? this.controlOnImageFillColorSecondary,
      controlOnImageFillColorTertiary: controlOnImageFillColorTertiary ?? this.controlOnImageFillColorTertiary,
      controlOnImageFillColorDisabled: controlOnImageFillColorDisabled ?? this.controlOnImageFillColorDisabled,
      accentFillColorDisabled: accentFillColorDisabled ?? this.accentFillColorDisabled,
      controlStrokeColorDefault: controlStrokeColorDefault ?? this.controlStrokeColorDefault,
      controlStrokeColorSecondary: controlStrokeColorSecondary ?? this.controlStrokeColorSecondary,
      controlStrokeColorOnAccentDefault: controlStrokeColorOnAccentDefault ?? this.controlStrokeColorOnAccentDefault,
      controlStrokeColorOnAccentSecondary:
          controlStrokeColorOnAccentSecondary ?? this.controlStrokeColorOnAccentSecondary,
      controlStrokeColorOnAccentTertiary: controlStrokeColorOnAccentTertiary ?? this.controlStrokeColorOnAccentTertiary,
      controlStrokeColorOnAccentDisabled: controlStrokeColorOnAccentDisabled ?? this.controlStrokeColorOnAccentDisabled,
      controlStrokeColorForStrongFillWhenOnImage:
          controlStrokeColorForStrongFillWhenOnImage ?? this.controlStrokeColorForStrongFillWhenOnImage,
      cardStrokeColorDefault: cardStrokeColorDefault ?? this.cardStrokeColorDefault,
      cardStrokeColorDefaultSolid: cardStrokeColorDefaultSolid ?? this.cardStrokeColorDefaultSolid,
      controlStrongStrokeColorDefault: controlStrongStrokeColorDefault ?? this.controlStrongStrokeColorDefault,
      controlStrongStrokeColorDisabled: controlStrongStrokeColorDisabled ?? this.controlStrongStrokeColorDisabled,
      surfaceStrokeColorDefault: surfaceStrokeColorDefault ?? this.surfaceStrokeColorDefault,
      surfaceStrokeColorFlyout: surfaceStrokeColorFlyout ?? this.surfaceStrokeColorFlyout,
      surfaceStrokeColorInverse: surfaceStrokeColorInverse ?? this.surfaceStrokeColorInverse,
      dividerStrokeColorDefault: dividerStrokeColorDefault ?? this.dividerStrokeColorDefault,
      focusStrokeColorOuter: focusStrokeColorOuter ?? this.focusStrokeColorOuter,
      focusStrokeColorInner: focusStrokeColorInner ?? this.focusStrokeColorInner,
      cardBackgroundFillColorDefault: cardBackgroundFillColorDefault ?? this.cardBackgroundFillColorDefault,
      cardBackgroundFillColorSecondary: cardBackgroundFillColorSecondary ?? this.cardBackgroundFillColorSecondary,
      smokeFillColorDefault: smokeFillColorDefault ?? this.smokeFillColorDefault,
      layerFillColorDefault: layerFillColorDefault ?? this.layerFillColorDefault,
      layerFillColorAlt: layerFillColorAlt ?? this.layerFillColorAlt,
      layerOnAcrylicFillColorDefault: layerOnAcrylicFillColorDefault ?? this.layerOnAcrylicFillColorDefault,
      layerOnAccentAcrylicFillColorDefault:
          layerOnAccentAcrylicFillColorDefault ?? this.layerOnAccentAcrylicFillColorDefault,
      layerOnMicaBaseAltFillColorDefault: layerOnMicaBaseAltFillColorDefault ?? this.layerOnMicaBaseAltFillColorDefault,
      layerOnMicaBaseAltFillColorSecondary:
          layerOnMicaBaseAltFillColorSecondary ?? this.layerOnMicaBaseAltFillColorSecondary,
      layerOnMicaBaseAltFillColorTertiary:
          layerOnMicaBaseAltFillColorTertiary ?? this.layerOnMicaBaseAltFillColorTertiary,
      layerOnMicaBaseAltFillColorTransparent:
          layerOnMicaBaseAltFillColorTransparent ?? this.layerOnMicaBaseAltFillColorTransparent,
      solidBackgroundFillColorBase: solidBackgroundFillColorBase ?? this.solidBackgroundFillColorBase,
      solidBackgroundFillColorSecondary: solidBackgroundFillColorSecondary ?? this.solidBackgroundFillColorSecondary,
      solidBackgroundFillColorTertiary: solidBackgroundFillColorTertiary ?? this.solidBackgroundFillColorTertiary,
      solidBackgroundFillColorQuarternary:
          solidBackgroundFillColorQuarternary ?? this.solidBackgroundFillColorQuarternary,
      solidBackgroundFillColorTransparent:
          solidBackgroundFillColorTransparent ?? this.solidBackgroundFillColorTransparent,
      solidBackgroundFillColorBaseAlt: solidBackgroundFillColorBaseAlt ?? this.solidBackgroundFillColorBaseAlt,
      systemFillColorSuccess: systemFillColorSuccess ?? this.systemFillColorSuccess,
      systemFillColorCaution: systemFillColorCaution ?? this.systemFillColorCaution,
      systemFillColorCritical: systemFillColorCritical ?? this.systemFillColorCritical,
      systemFillColorNeutral: systemFillColorNeutral ?? this.systemFillColorNeutral,
      systemFillColorSolidNeutral: systemFillColorSolidNeutral ?? this.systemFillColorSolidNeutral,
      systemFillColorAttentionBackground: systemFillColorAttentionBackground ?? this.systemFillColorAttentionBackground,
      systemFillColorSuccessBackground: systemFillColorSuccessBackground ?? this.systemFillColorSuccessBackground,
      systemFillColorCautionBackground: systemFillColorCautionBackground ?? this.systemFillColorCautionBackground,
      systemFillColorCriticalBackground: systemFillColorCriticalBackground ?? this.systemFillColorCriticalBackground,
      systemFillColorNeutralBackground: systemFillColorNeutralBackground ?? this.systemFillColorNeutralBackground,
      systemFillColorSolidAttentionBackground:
          systemFillColorSolidAttentionBackground ?? this.systemFillColorSolidAttentionBackground,
      systemFillColorSolidNeutralBackground:
          systemFillColorSolidNeutralBackground ?? this.systemFillColorSolidNeutralBackground,
    );
  }
}
