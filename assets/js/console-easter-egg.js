console.log(
  "%c" +
    `
                                                                                 _     _g
        ggmmmmmmmmgg                                           =qg~~~~__        9@)  'T@
       ,P        @@                                             [@'    @@             @F
       /       _@P            _                                 @@     |@g           !@
      '       g@'       _  "B@'   gg@   o@@!     _/ T@         |@'     |@/    g@)    @/      _  9g  ,@@     @,
            _@D        +    @9     @9 _' |@     i   AD         @@      @W   , ,@    A@      g   @F ,  @g    @
           o@"        |    @@     /@ /   @/    @'  /"          @"    _@"      @T    @'     B   JF     @@    @
         ,@@         @     @'     @ /   gW    &F,<             @mmgj         {@    |@     g/_:'       [@    '
        /@F         @   , @9     @//   /@    ;@              ; /  {@        ,[    ,|     /@           |@   *
      ,g@          @9  , /@  ,  /@/   .@' ,  @@              @     @@       @"    @|  ,  @N           |@  /
     _@f          ;@  ;  @' '   @?    @F     @g   ,         ;@      @,     AW ,  /@  '   @]   ,       |@ ,
    @@         f  @@y"  @B+    @F    {@;     @@_,+          @@      [@    ,@k"   @E:     @@  /        |@,
  _@8        _@   <"    >      "     "        <>           ,@|       @p   0"    'P       "B+          [W
 dBBmmmmmmm0BB'                                           _@@h       '@L                              )
                                                                      "
   _!@@@g____ ,q         __L    @g__               @@@@@@@@@@@@        __o@   @@@@@ !@@@@@
   @@@@@@@@@@l_  ____g@@@@@@L  [@@@@@@             PPPPPPPPPPPP ___g@@@@@@@@, @@@@@ |@@@@@
   BB@@@@BB@@@@  @@@@@@@@@@@D^   "4@@              @@@@@@@@@@@@ '@@@@@@@@@@D" @@@@@ |@@@@@|@@@@@@@@@@@@|
    [@@@g :@@@W  '@@@@@@@@]         ___g@@|        PPPPPPPP@@@@  Q@@B@@@@@    """""_|@@@@W|@@@@@@@@@@@@|
    [@@@@gggggg!     [@@@@]   @@@@@@@@@@@@@        gggggg@@@@@@      @@@@@    @@@@@@@@@@@|
     @@@@@@@@@@|     [@@@@]   [@@@@@@@@@BP         [@@@@@@@@@P       @@@@@    @@@@@@@@@B"
        """""""'              '"""'
`,
  "color: #fff; font-size: 8px; font-family: monospace; font-weight: bold; line-height: 0.5;",
);

const messageContent = [
  "Hello there! Nice to meet you!",
  "YOUR CURIOSITY IS DELIGHTFUL AND WELCOME.",
  "THE CODE IS ON GITHUB https://github.com/zaneriley/personal-site",
  "AND DESIGNS IN FIGMA https://www.figma.com/design/zDOcBhnjTDCWmc6OFgeoUc/Zane-Riley's-Product-Portfolio?node-id=2209-559&t=0gZqDDkC2pYanuW3-0",
  "MAY YOUR JOURNEY BE FILLED WITH WONDER AND DISCOVERY.",
  "THIS TERMINAL WISHES YOU WELL, FELLOW SEEKER OF KNOWLEDGE.",
  "<systempily happily humming>",
];

const baseStyle =
  'font-family: "Courier New", monospace; font-size: 14px; line-height: 1.5; text-shadow: 0 0 5px rgba(255,255,255,0.7);';
const glitchStyle = `${baseStyle} color: #e0e0e0; text-shadow: 2px 2px #ff00de, -2px -2px #00ff9f;`;
const normalStyle = `${baseStyle} color: #b0b0b0;`;
const systemStyle = `${baseStyle} color: #00ff9f; font-style: italic;`;

console.log("%c[SYSTEM BOOT]", systemStyle);

messageContent.forEach((line, index) => {
  setTimeout(() => {
    if (index === 0 || index === messageContent.length - 1) {
      console.log(`%c${line}`, glitchStyle);
    } else {
      console.log(`%c${line}`, normalStyle);
    }

    if (index === messageContent.length - 1) {
      console.log("%c[SYSTEM SHUTDOWN]", systemStyle);
    }
  }, index * 1000);
});
