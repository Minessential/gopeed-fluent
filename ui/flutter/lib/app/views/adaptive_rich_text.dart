import 'package:flutter/material.dart';

class AdaptiveRichText extends StatelessWidget {
  final InlineSpan longTextSpan;
  final InlineSpan shortTextSpan;
  final TextStyle? style;
  final TextAlign? textAlign;

  const AdaptiveRichText({
    Key? key,
    required this.longTextSpan,
    required this.shortTextSpan,
    this.style,
    this.textAlign,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textDirection = Directionality.of(context);
        final effectiveStyle = style ?? DefaultTextStyle.of(context).style;

        final textPainter = TextPainter(
          text: TextSpan(style: effectiveStyle, children: [longTextSpan]),
          maxLines: 1,
          textDirection: textDirection,
          textAlign: textAlign ?? TextAlign.start,
        );

        textPainter.layout(maxWidth: constraints.maxWidth);

        if (textPainter.didExceedMaxLines) {
          return Text.rich(
            shortTextSpan,
            style: effectiveStyle,
            textAlign: textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        } else {
          return Text.rich(longTextSpan, style: effectiveStyle, textAlign: textAlign);
        }
      },
    );
  }
}
