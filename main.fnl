;; sn4k3
;;
;; Copyright (c) 2022 Omar Polo
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the MIT license. See LICENSE for
;; details.

(local tick (require :tick))

(var game-state :menu) ;; :menu :game :pause :over
(var tick-event nil)

(var score 0)
(var snake-body [])
(var candies [])

(var direction :right)

(local ratio 20)

(local width 30)
(local height 20)

(local window-width (* ratio width))
(local window-height (* ratio height))

(fn hit? [x y seq]
  "Return the index of the element of seq that is on (x, y), or nil."
  (accumulate [index nil
               i r (ipairs seq)
               &until index]
    (if (and (= x (. r :x))
             (= y (. r :y)))
        i)))

(fn place-candy []
  (var done? false)
  (while (not done?)
    (let [x (math.random (- width 1))
          y (math.random (- height 1))]
      (when (and (not (hit? x y snake-body))
                 (not (hit? x y candies)))
        (set done? true)
        (table.insert candies {: x : y})))))

(fn wrap [val max]
  (if (< val 0)
      (- max 1)
      (< val max)
      val
      0))

(fn compute-step [{: x : y}]
  (match direction
    :up (values x (wrap (- y 1) height))
    :left (values (wrap (- x 1) width) y)
    :right (values (wrap (+ x 1) width) y)
    :down (values x (wrap (+ y 1) height))))

(fn move-snake []
  (let [(x y) (compute-step (. snake-body 1))]
    (if (hit? x y snake-body)
        (do
          (print "GAME OVER!")
          (print "score:" score)
          (set game-state :over))
        (do
          (match (hit? x y candies)
            nil (table.remove snake-body)
            i (do (table.remove candies i)
                  (place-candy)
                  (set score (+ 1 score))))
          (table.insert snake-body 1 {: x : y})))))

(fn centered-text [x y rectw recth scale text]
  (let [font (love.graphics.getFont)
        tw (font:getWidth text)
        th (font:getHeight)]
    (love.graphics.print text
                         (+ (* x ratio) (* (/ rectw 2) ratio))
                         (+ (* y ratio) (* (/ recth 2) ratio))
                         0 scale scale
                         (/ tw 2)
                         (/ th 2))))

(fn menu-draw []
  (love.graphics.setColor 0 1 0 1)
  (centered-text 0 0 width height 2 "SN4K3")
  (centered-text 0 6 width height 1 "press any key to play"))

(fn game-draw []
  (love.graphics.setColor 255 255 255)
  (each [_ r (ipairs snake-body)]
    (let [{: x : y} r]
      (love.graphics.rectangle :fill (* ratio x) (* ratio y) 20 20)))

  (love.graphics.setColor 255 0 0)
  (each [_ r (ipairs candies)]
    (let [{: x : y} r]
      (love.graphics.rectangle :fill (* ratio x) (* ratio y) 20 20))))

(fn pause-draw []
  (game-draw)
  (love.graphics.setColor 0 1 0 1)
  (centered-text 0 0 width height 2 "PAUSED")
  (centered-text 0 6 width height 1 "press any key to resume"))

(fn over-draw []
  (game-draw)
  (love.graphics.setColor 0 1 0 1)
  (centered-text 0 0 width height 2 "GAME OVER!")
  (centered-text 0 6 width height 1 (string.format "score: %03d" score)))

(fn game-init []
  (set snake-body [{:x 14 :y 9}
                   {:x 13 :y 9}
                   {:x 12 :y 9}
                   {:x 11 :y 9}])
  (set candies [])
  (for [i 1 5]
    (place-candy))
  (when tick-event
    (tick.remove tick-event))
  (set tick-event (tick.recur move-snake .25)))

(fn love.load []
  (love.window.updateMode window-width window-height {:fullscreen false}))

(fn love.draw []
  (love.graphics.setColor 0 0 0)
  (love.graphics.rectangle :fill 0 0 window-width window-height)

  (if (= game-state :menu)
      (menu-draw)

      (= game-state :game)
      (game-draw)

      (= game-state :pause)
      (pause-draw)

      (= game-state :over)
      (over-draw)))

(fn key-ok? [key]
  (and (not= key "lctrl")
       (not= key "lshift")
       (not= key "lgui")
       (not= key "lalt")
       (not= key "rctrl")
       (not= key "rshift")
       (not= key "rgui")
       (not= key "ralt")
       (not= key "scrollock")))

(fn love.keypressed [key]
  (if (or (= game-state :menu)
          (= game-state :over))
      (if (= key :q)     (love.event.quit 0)
          (key-ok? key)  (do (set game-state :game)
                             (game-init)))

      (= game-state :game)
      (match key
        (where (or :up :down :left :right)) (set direction key)
        (where (or :p :escape)) (set game-state :pause))

      (= game-state :pause)
      (when (key-ok? key)
        (set game-state :game))))

(fn love.update [dt]
  (when (= game-state :game)
    (tick.update dt)))
