import 'package:flutter/material.dart';


class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({Key? key, required this.label, required this.value})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xff333333),
              fontWeight: FontWeight.w300,
              fontFamily: 'lexend',
              fontSize: 13,
            ),
          ),
        ),
        const Text(
          ":",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontFamily: "lexend",
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                color: Color(0xff333333),
                fontWeight: FontWeight.w300,
                fontFamily: 'lexend',
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class InfoRow1 extends StatelessWidget {
  final String label;
  final String value;
  final FontWeight? fontWeight;
  final double? fontSize;
  final double? labelwidth;

  const InfoRow1({Key? key, required this.label, required this.value,this.fontWeight,this.fontSize,this.labelwidth})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.sizeOf(context).width;
    return Row(
      spacing: 10,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width:labelwidth ??width*0.25,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
              fontSize: 16,
            ),
          ),
        ),
        Text(
          ":",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            fontSize: 13,
          ),
        ),
        SizedBox(width: 6,),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(textAlign: TextAlign.start,
              value,
              overflow: TextOverflow.ellipsis,
              maxLines: 5,
              style:  TextStyle(
                color: Color(0xff666666),
                fontWeight: fontWeight??FontWeight.w500,
                letterSpacing: 0,
                fontSize:fontSize ?? 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
//
// class InfoRow3 extends StatelessWidget {
//   final String label;
//   final String value;
//
//   const InfoRow3({Key? key, required this.label, required this.value})
//       : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       spacing: 10,
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         SizedBox(
//           width: SizeConfig.screenWidth*0.5,
//           child: Text(
//             label,
//             style: TextStyle(
//               color: black3,
//               fontWeight: FontWeight.w400,
//               fontFamily: 'lexend',
//               letterSpacing: 0,
//               fontSize: 14,
//             ),
//           ),
//         ),
//         Text(
//           ":",
//           style: TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.w600,
//             fontFamily: "lexend",
//             letterSpacing: 0,
//             fontSize: 13,
//           ),
//         ),
//         SizedBox(width: 6,),
//         Expanded(
//           child: Align(
//             alignment: Alignment.centerLeft,
//             child: Text(
//               value,
//               overflow: TextOverflow.ellipsis,
//               maxLines: 1,
//               style: const TextStyle(
//                 color: Color(0xff333333),
//                 fontWeight: FontWeight.w500,
//                 fontFamily: 'lexend',
//                 letterSpacing: 0,
//                 fontSize: 14,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// class InfoRow2 extends StatelessWidget {
//   final String label;
//   final String? optionalLabel; // Optional second text
//   final String value;
//
//   const InfoRow2({
//     Key? key,
//     required this.label,
//     this.optionalLabel, // Made optional
//     required this.value,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             RichText(
//               text: TextSpan(
//                 children: [
//                   TextSpan(
//                     text: label,
//                     style: TextStyle(
//                       color: black,
//                       fontWeight: FontWeight.w400,
//                       fontFamily: 'lexend',
//                       letterSpacing: 0,
//                       fontSize: 12,
//                     ),
//                   ),
//                   if (optionalLabel != null) ...[
//                     TextSpan(
//                       text: optionalLabel,
//                       style: TextStyle(
//                         color: black1,
//                         fontWeight: FontWeight.w200,
//                         fontFamily: 'lexend',
//                         fontSize: 8,
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//             Expanded(
//               child: Align(
//                 alignment: Alignment.centerRight,
//                 child: Text(
//                   value,
//                   overflow: TextOverflow.ellipsis,
//                   maxLines: 1,
//                   style: const TextStyle(
//                     color: Color(0xff333333),
//                     fontWeight: FontWeight.w600,
//                     letterSpacing: 0,
//                     fontFamily: 'lexend',
//                     fontSize: 14,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }
