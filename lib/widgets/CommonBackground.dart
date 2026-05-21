import 'package:flutter/material.dart';

class Background extends StatelessWidget {
  final Widget child;
  final String? bgImagePath;
  final Color? bgColor;

  const Background({
    super.key,
    required this.child,
    this.bgImagePath,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Positioned.fill(
          child: Opacity(
            opacity: 0.15,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(bgImagePath ?? "assets/images/bc.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class Background1 extends StatelessWidget {
  final Widget child;
  final String? bgImagePath;

  const Background1({super.key, required this.child, this.bgImagePath});

  @override
  Widget build(BuildContext context) {
    // Diagonal IND CLASSIFIEDS logo watermark commented out 2026-05-12
    // — felt too heavy on the Select Sub-Category screen during the
    // post-ad flow. Restore by uncommenting the Stack below.
    return child;
    // return Stack(
    //   fit: StackFit.expand,
    //   children: [
    //     Center(
    //       child: Opacity(
    //         opacity: 0.05,
    //         child: Transform.rotate(
    //           angle: -45 * 3.1415926535 / 180, // -45° diagonal
    //           child: Image.asset(
    //             bgImagePath ?? "assets/images/logo.png",
    //             width: 382.8654593415135,
    //             height: 202.9186919251232,
    //             fit: BoxFit.contain,
    //           ),
    //         ),
    //       ),
    //     ),
    //
    //     // Foreground child UI
    //     child,
    //   ],
    // );
  }
}
