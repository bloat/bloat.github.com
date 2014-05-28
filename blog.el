
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

(defun slothrop-blog-get-entries (html-buffer)
  (save-excursion
    (set-buffer html-buffer)
    ;; Get the items that represent blog entries.
    (subseq
     ;; Get the content from the body.
     (caddr
      ;; Get the body from the html.
      (cadddr (libxml-parse-xml-region (point-min) (point-max)))) 
     5)))

(defun slothrop-blog-get-entry-title (entry)
  (nth 3 (nth 2 entry)))

(defun slothrop-blog-get-entry-content (entry)
  (cddr (nth 3 entry)))

(defun slothrop-blog-get-entry-id (entry)
  (cdaadr (caddr entry)))

(defun slothrop-blog-get-entry-date (entry)
  (substring (nth 2 (nth 2 (nth 2 (caddr entry)))) 1 -1))

(defun slothrop-blog-serialize (node)
  (concat "&lt;" 
	  (symbol-name (car node))
	  (when (cadr node)
	    (concat " "
		    (mapconcat #'(lambda (x)
				   (concat
				    (symbol-name (car x))
				    "=\""
				    (cdr x)
				    "\""))
			       (cadr node)
			       " ")))
	  "&gt;"
	  (mapconcat #'(lambda (x) 
			 (cond ((stringp x) x)
			       ((listp x) (slothrop-blog-serialize x))))
		     (cddr node)
		     "")
	  "&lt;/" 
	  (symbol-name (car node)) 
	  "&gt;"))

(defconst slothrop-blog-preamble
"<?xml version='1.0' encoding='UTF-8'?>
<rss xmlns:atom='http://www.w3.org/2005/Atom' version='2.0'>
  <channel>
    <atom:id>git.slothrop.net</atom:id>
    <lastBuildDate>xxxTIMExxx</lastBuildDate>
    <title>Some Clojure Projects</title>
    <description>
    </description>
    <link>http://git.slothrop.net</link>
    <managingEditor>andrew.cowper@slothrop.net (Andrew Cowper)</managingEditor>")

(defconst slothrop-blog-postamble
"\n  </channel>
</rss>")

(defun slothrop-blog-wrap-content (index title id date content)
  (concat "
    <item>
      <guid isPermaLink='false'>git.slothrop.net." (number-to-string index) "</guid>
      <pubDate>" date "</pubDate>
      <atom:updated>" date "</atom:updated>
      <title>" title "</title>
      <description>\n" content "\n      </description>
      <link>http://git.slothrop.net/#" id "</link>
      <author>Andrew Cowper</author>
    </item>"))

(defun slothrop-blog-to-rss (html-buffer rss-buffer)
  (interactive "bHTML Buffer: \nbRSS Buffer: ")
  (save-excursion
    (set-buffer rss-buffer)
    (delete-region (point-min) (point-max))
    (insert (replace-regexp-in-string 
	     "xxxTIMExxx"  
	     (format-time-string "%a, %e %b %Y %T %z")
	     slothrop-blog-preamble
	     t
	     t))
    (apply #'insert 
	   (let ((blog-index 0))
	     (mapcar #'(lambda (x) 
			 (setq blog-index (1+ blog-index))
			 (slothrop-blog-wrap-content
			  blog-index
			  (slothrop-blog-get-entry-title x)
			  (slothrop-blog-get-entry-id x)
			  (slothrop-blog-get-entry-date x)
			  (mapconcat #'slothrop-blog-serialize
				     (slothrop-blog-get-entry-content x) "\n")))
		     (reverse (slothrop-blog-get-entries html-buffer)))))
    (insert slothrop-blog-postamble)))

(defun slothrop-publish-blog (org-buffer html-file rss-buffer)
  (interactive "bOrg Buffer: \nFHTML File: \nbRSS Buffer: ")
  (save-excursion
    (set-buffer org-buffer)
    (org-export-to-file 'html html-file))
  (let ((html-buffer (find-file-noselect html-file)))
    (slothrop-blog-fix-tags org-buffer html-buffer)
    (save-buffer html-buffer)
    (slothrop-blog-to-rss html-buffer rss-buffer)
    (save-buffer rss-buffer)))
