(** levinson.ml --- an implementation of Levinson-Durbin recursion

    [MIT Lisence] Copyright (C) 2015 Akinori ABE
*)

open Format

module Array = struct
  include Array

  (** [mapi_sum f [|x1; x2; ...; xn|]] is [f x1 +. f x2 +. ... +. f xn]. *)
  let mapi_sum f x =
    let acc = ref 0.0 in
    for i = 0 to length x - 1 do acc := !acc +. f i x.(i) done;
    !acc
end

(** [autocorr x tau] computes autocorrelation [[|r(0); r(1); ...; [r(tau)]|]].
*)
let autocorr x tau =
  let n = Array.length x in
  let r = Array.make (tau + 1) 0.0 in
  for i = 0 to tau do
    for t = 0 to n-i-1 do r.(i) <- r.(i) +. x.(t) *. x.(t + i) done
  done;
  r

(** [levinson r] computes AR coefficients by Levinson-Durbin recursion where
    [r = [|r(0); r(1); ...; r(n)|]] is autocorrelation.
    @return [([ar(1); ar(2); ...; ar(n)], sigma2)] where [ar(i)] is the [i]-th
    coefficient of AR([n]) and [sigma2] is variance of errors.
*)
let levinson r =
  let n = Array.length r in
  if n = 0 then failwith "empty autocorrelation";
  let rec aux m ar sigma2 =
    let m' = m + 1 in
    if m' = n then (ar, sigma2)
    else begin
      let ar' = Array.make (m+1) 0.0 in
      ar'.(m) <- (r.(m+1) -. Array.mapi_sum (fun i ai -> ai *. r.(m-i)) ar)
                 /. sigma2;
      for i = 0 to m-1 do ar'.(i) <- ar.(i) -. ar'.(m) *. ar.(m-1-i) done;
      let sigma2' = sigma2 *. (1.0 -. ar'.(m) *. ar'.(m)) in
      aux (m+1) ar' sigma2'
    end
  in
  aux 0 [||] r.(0)

let print_ar_coeffs label data order =
  let r = autocorr data (order + 1) in
  let (ar, sigma2) = levinson r in
  ()
  (* let ar_str = Array.to_list ar *)
  (*              |> List.map (sprintf "%g") *)
  (*              |> String.concat "; " in *)
  (* printf "%s:@\n  @[AR = [|%s|]@\nsigma^2 = %g@]@." label ar_str sigma2 *)

let gather t =
  t.Unix.tms_utime +. t.Unix.tms_stime +. t.Unix.tms_cutime +. t.Unix.tms_cstime

let c = Gc.get ()
let () = Gc.set
    { c with Gc.minor_heap_size = 32000000;
             Gc.space_overhead = max_int }

let main () =
  let order = 20 in (* AR order *)
  print_ar_coeffs "Sound /a/" Dataset.a order;
  print_ar_coeffs "Sound /i/" Dataset.i order;
  print_ar_coeffs "Sound /u/" Dataset.u order;
  print_ar_coeffs "Sound /e/" Dataset.e order;
  print_ar_coeffs "Sound /o/" Dataset.o order

let () =
  let t1 = Unix.times () in
  for i = 1 to 5000 do
    main () |> ignore;
    Gc.minor ()
  done;
  let t2 = Unix.times () in
  gather t2 -. gather t1
  |> Format.printf "%f\n"
