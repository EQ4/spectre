(import array struct sys wave)
(import [PIL [Image]])
(import [numpy.fft [ifft]])

(setv filename (get sys.argv 1))
(setv half-win 512)
(setv sampling-frequency 44100.0)

(defn load-image [file]
  ; load, then greyscale
  (setv im (.convert (.open Image file) "L"))
  (let [[width (get im.size 0)]
        [height (get im.size 1)]
        [ratio (/ half-win width)]]
    (.resize im (, half-win (int (* height ratio))))))

(setv im (load-image filename))
(setv pad (* [0] half-win))

(defn pix [im x y] (.getpixel im (, x y)))

(setv results [])

(defn transform [im]
  (let [[width (get im.size 0)]
        [height (get im.size 1)]]
    (for [i (range height)]
      (setv line [])
      (for [j (range width)]
        (.append line (pix im j i)))

      (setv result (ifft (+ line pad)))
      (.append results result))))

(setv im (transform im))
(setv sample-len (* (len (get results 0)) (len results)))
(print "length (s): " (/ sample-len sampling-frequency))

(setv w (.open wave (+ filename ".wav") "w"))
(.setparams w (, 1 2 sampling-frequency sample-len "NONE" ""))
(setv largest-amp 0.0)
(setv smallest-amp 0.0)

(setv largest-amp (->> results (flatten) (map (fn [x] (abs x.real))) (max)))

(print "max amp: " largest-amp)

(setv bigint (** 2 14))
(setv written 0)
(for [line results]
  (print "written " written " of " sample-len)
  (setv buf (str ""))
  (for [i line]
    (setv val i.real)
    (setv buf (str (+ buf (.pack struct "h" (int (* val (/ bigint largest-amp)))))))
    )
  (.writeframes w buf)
  (setv written (+ written (/ (len buf) 2))))

(.close w)