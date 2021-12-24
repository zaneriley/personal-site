export default function pxToRem(int, rootInt) {
  if (!rootInt) rootInt = 16;
  return int / rootInt;
}
