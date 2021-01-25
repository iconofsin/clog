(defpackage #:clog-user
  (:use #:cl #:clog)
  (:export start-tutorial))

(in-package :clog-user)

(defun on-click (obj)
  (setf (text obj) "DEAD")
  (setf (connection-data-item obj "done") t)
  (set-on-click obj nil))

(defun on-new-window (body)
  (handler-case   ; Disconnects from the browser can be handled gracefully using the condition system.
      (progn
	(setf (title (html-document body)) "Tutorial 7")

	(setf (hiddenp (prog1
			   (create-child body "<h2>KILL Darth's Tie Fighter - Click on it!</h2>")
			 (sleep 2))) t)		 

	(let* ((mover (create-div body :content "(-o-)"))
	       bounds-x bounds-y mover-x mover-y)
	  
	  (flet ((set-bounds ()
		   (setf bounds-x (parse-integer (width (window body)) :junk-allowed t))
		   (setf bounds-y (parse-integer (height (window body)) :junk-allowed t))))
	    (set-bounds)
	    (setf mover-x (random bounds-x))
	    (setf mover-y (random bounds-y))
	    
	    (set-on-resize (window body)
			   (lambda (obj)
			     (declare (ignore obj))
			     (set-bounds))))
	  
	  (setf (positioning mover) :fixed)
	  (set-on-click mover #'on-click)

	  (bordeaux-threads:make-thread    ; In addtion to the main task (the on-new-window)
	   (lambda ()                      ; and the task created for each event like clicks
	     (loop                         ; threads can be created as needed.
		   (unless (validp body)
		     (return))
		   (when (connection-data-item body "done")
		     (return))
		   
		   (sleep .5)
		   (setf (text mover) ")-o-(")
		   (sleep .2)
		   (setf (text mover) "(-o-)"))
	     (setf (inner-html mover) "<H1>GAME OVER</H1>")))
	  
	  (loop
	    (unless (validp body)
	      (return))
	    (when (connection-data-item body "done")
	      (return))
	    
	    (setf (top mover) (format nil "~Apx" mover-y))
	    (setf (left mover) (format nil "~Apx" mover-x))
	    
	    (if (= (random 2) 0)
		(incf mover-y (random 10))
		(decf mover-y (random 10)))
	    (if (= (random 2) 0)
		(incf mover-x (random 10))
		(decf mover-x (random 10)))
	    
	    (when (< mover-x 0)
	      (setf mover-x 0))
	    (when (> mover-x bounds-x)
	      (setf mover-x bounds-x))
	    
	    (when (< mover-y 0)
	      (setf mover-y 0))
	    (when (> mover-y bounds-y)
	      (setf mover-y bounds-y))
	    
	    (sleep .02))))
    (error (c)
      (format t "Lost connection.~%~%~A" c))))
;; There is no reason to run (run body) here as we check for (validp body)
;; and once the connection dies so does the on-new-window thread.

(defun start-tutorial ()
  "Start tutorial."

  (initialize #'on-new-window)
  (open-browser))
