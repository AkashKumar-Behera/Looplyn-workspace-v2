import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const String _rawSvg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <defs>
    <filter id="bg-red-glow" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur stdDeviation="50" />
    </filter>
    <filter id="red-shape-glow" x="-30%" y="-30%" width="160%" height="160%">
      <feDropShadow dx="0" dy="0" stdDeviation="16" flood-color="#dc2626" flood-opacity="0.85"/>
    </filter>
    <filter id="card-shadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="4" stdDeviation="10" flood-color="#000000" flood-opacity="0.3"/>
    </filter>
  </defs>

  <circle cx="256" cy="256" r="160" fill="#dc2626" opacity="0.4" filter="url(#bg-red-glow)" />

  <g transform="translate(64, 64) scale(0.75)">
    <!-- Bottom right wide card - slate gray -->
    <path fill="#52525b" d="m497 362h-280c-8.284 0-15 6.716-15 15v120c0 8.284 6.716 15 15 15h280c8.284 0 15-6.716 15-15v-120c0-8.284-6.716-15-15-15z"/>
    <!-- Bottom left card - Glowing Red -->
    <path fill="#dc2626" filter="url(#red-shape-glow)" d="m155 362h-140c-8.284 0-15 6.716-15 15v120c0 8.284 6.716 15 15 15h140c8.284 0 15-6.716 15-15v-120c0-8.284-6.716-15-15-15z"/>
    <!-- Main left tall card - Pure White with subtle stroke & shadow -->
    <path fill="#ffffff" stroke="#cbd5e1" stroke-width="4" filter="url(#card-shadow)" d="m15 332h210c8.284 0 15-6.716 15-15v-302c0-8.284-6.716-15-15-15h-210c-8.284 0-15 6.716-15 15v302c0 8.284 6.716 15 15 15z"/>
    <!-- Top right slashed block - Glowing Red -->
    <path fill="#dc2626" filter="url(#red-shape-glow)" d="m497 0h-210c-8.284 0-15 6.716-15 15v180.662l240-91.428v-89.234c0-8.284-6.716-15-15-15z"/>
    <!-- Middle right slashed block - Pure White with subtle stroke & shadow -->
    <path fill="#ffffff" stroke="#cbd5e1" stroke-width="4" filter="url(#card-shadow)" d="m272 317c0 8.284 6.716 15 15 15h210c8.284 0 15-6.716 15-15v-180.662l-240 91.428z"/>
  </g>
</svg>''';

class LooplynLogo extends StatelessWidget {
  final double size;
  const LooplynLogo({super.key, this.size = 32.0});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _rawSvg,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
