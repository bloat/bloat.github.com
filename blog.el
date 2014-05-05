
(defun slothrop-blog-fix-tags (org-buffer html-buffer)
  (interactive "bOrg Buffer: \nbHTML Buffer: ")
  (save-excursion
    (let ((sec 0))
      (set-buffer org-buffer)
      (org-map-entries #'(lambda () 
			   (incf sec)
			   (let ((id-tag (concat "\"" (org-entry-get (point) "tag") "\""))
				 (anchor-tag (concat "\"#" (org-entry-get (point) "tag") "\"")))
			     (save-excursion
			       (set-buffer html-buffer)
			       (goto-char (point-min))
			       (while (re-search-forward (concat "\"sec-" (number-to-string sec) "\"") nil t)
				 (replace-match id-tag))
			       (goto-char (point-min))
			       (while (re-search-forward (concat "\"#sec-" (number-to-string sec) "\"") nil t)
				 (replace-match anchor-tag)))))))))
