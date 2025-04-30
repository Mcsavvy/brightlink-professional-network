;; brightlink-core
;; 
;; This contract implements the core functionality for BrightLink Professional Network,
;; a decentralized professional networking application built on the Stacks blockchain.
;; It allows users to manage professional connections, store contact details, categorize 
;; relationships, schedule follow-ups, and maintain interaction history - all while 
;; ensuring data sovereignty and privacy.

;; =============================
;; Constants and Error Codes
;; =============================

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-CONTACT-EXISTS (err u101))
(define-constant ERR-CONTACT-NOT-FOUND (err u102))
(define-constant ERR-INVALID-PARAMS (err u103))
(define-constant ERR-FOLLOW-UP-NOT-FOUND (err u104))
(define-constant ERR-INTERACTION-NOT-FOUND (err u105))
(define-constant ERR-CATEGORY-EXISTS (err u106))
(define-constant ERR-CATEGORY-NOT-FOUND (err u107))

;; Connection categories
(define-constant CATEGORY-COLLEAGUE u1)
(define-constant CATEGORY-CLIENT u2)
(define-constant CATEGORY-MENTOR u3)
(define-constant CATEGORY-MENTEE u4)
(define-constant CATEGORY-PARTNER u5)
(define-constant CATEGORY-OTHER u6)

;; =============================
;; Data Maps and Variables
;; =============================

;; Stores basic contact profile information
;; The key is a tuple of (owner, contact-id) where owner is the principal who owns the contact
;; and contact-id is a unique identifier for this contact in the owner's network
(define-map contacts 
  { owner: principal, contact-id: uint }
  {
    name: (string-ascii 64),
    title: (string-ascii 64),
    company: (string-ascii 64),
    email: (string-ascii 64),
    phone: (string-ascii 32),
    location: (string-ascii 64),
    category: uint,
    public-profile: (optional principal),
    date-added: uint,
    last-updated: uint,
    importance-score: uint,
    notes: (string-utf8 500)
  }
)

;; Stores custom categories created by users
(define-map custom-categories
  { owner: principal, category-id: uint }
  { 
    name: (string-ascii 32),
    description: (string-utf8 100)
  }
)

;; Tracks the next available contact ID for each user
(define-map next-contact-id
  { owner: principal }
  { value: uint }
)

;; Tracks the next available custom category ID for each user
(define-map next-category-id
  { owner: principal }
  { value: uint }
)

;; Stores scheduled follow-ups for contacts
(define-map follow-ups
  { owner: principal, follow-up-id: uint }
  {
    contact-id: uint,
    due-date: uint,
    title: (string-ascii 64),
    description: (string-utf8 200),
    completed: bool,
    reminder-sent: bool
  }
)

;; Tracks the next available follow-up ID for each user
(define-map next-follow-up-id
  { owner: principal }
  { value: uint }
)

;; Stores interaction history with contacts
(define-map interactions
  { owner: principal, interaction-id: uint }
  {
    contact-id: uint,
    date: uint,
    type: (string-ascii 32),
    notes: (string-utf8 500),
    outcome: (string-utf8 200)
  }
)

;; Tracks the next available interaction ID for each user
(define-map next-interaction-id
  { owner: principal }
  { value: uint }
)

;; =============================
;; Private Functions
;; =============================

;; Get the next contact ID for a user and increment the counter
(define-private (get-and-increment-contact-id (owner principal))
  (let ((current-id (default-to { value: u1 } 
                      (map-get? next-contact-id { owner: owner }))))
    (map-set next-contact-id
      { owner: owner }
      { value: (+ (get value current-id) u1) })
    (get value current-id)))

;; Get the next follow-up ID for a user and increment the counter
(define-private (get-and-increment-follow-up-id (owner principal))
  (let ((current-id (default-to { value: u1 } 
                      (map-get? next-follow-up-id { owner: owner }))))
    (map-set next-follow-up-id
      { owner: owner }
      { value: (+ (get value current-id) u1) })
    (get value current-id)))

;; Get the next interaction ID for a user and increment the counter
(define-private (get-and-increment-interaction-id (owner principal))
  (let ((current-id (default-to { value: u1 } 
                      (map-get? next-interaction-id { owner: owner }))))
    (map-set next-interaction-id
      { owner: owner }
      { value: (+ (get value current-id) u1) })
    (get value current-id)))

;; Get the next category ID for a user and increment the counter
(define-private (get-and-increment-category-id (owner principal))
  (let ((current-id (default-to { value: u100 } 
                      (map-get? next-category-id { owner: owner }))))
    (map-set next-category-id
      { owner: owner }
      { value: (+ (get value current-id) u1) })
    (get value current-id)))

;; Check if a contact exists for a given owner and contact-id
(define-private (contact-exists? (owner principal) (contact-id uint))
  (is-some (map-get? contacts { owner: owner, contact-id: contact-id })))

;; =============================
;; Read-Only Functions
;; =============================

;; Get a contact's details - only available to the owner
(define-read-only (get-contact (contact-id uint))
  (let ((owner tx-sender))
    (match (map-get? contacts { owner: owner, contact-id: contact-id })
      contact-details (ok contact-details)
      ERR-CONTACT-NOT-FOUND)))

;; Get a public view of a contact - limited information for network sharing
(define-read-only (get-public-contact (owner principal) (contact-id uint))
  (match (map-get? contacts { owner: owner, contact-id: contact-id })
    contact-details (ok {
      name: (get name contact-details),
      title: (get title contact-details),
      company: (get company contact-details),
      public-profile: (get public-profile contact-details)
    })
    ERR-CONTACT-NOT-FOUND))

;; Get all scheduled follow-ups for the user's contacts
(define-read-only (get-follow-up (follow-up-id uint))
  (let ((owner tx-sender))
    (match (map-get? follow-ups { owner: owner, follow-up-id: follow-up-id })
      follow-up-details (ok follow-up-details)
      ERR-FOLLOW-UP-NOT-FOUND)))

;; Get a specific interaction record
(define-read-only (get-interaction (interaction-id uint))
  (let ((owner tx-sender))
    (match (map-get? interactions { owner: owner, interaction-id: interaction-id })
      interaction-details (ok interaction-details)
      ERR-INTERACTION-NOT-FOUND)))

;; Get a custom category
(define-read-only (get-custom-category (category-id uint))
  (let ((owner tx-sender))
    (match (map-get? custom-categories { owner: owner, category-id: category-id })
      category-details (ok category-details)
      ERR-CATEGORY-NOT-FOUND)))

;; =============================
;; Public Functions
;; =============================

;; Add a new professional contact to the user's network
(define-public (add-contact
    (name (string-ascii 64))
    (title (string-ascii 64))
    (company (string-ascii 64))
    (email (string-ascii 64))
    (phone (string-ascii 32))
    (location (string-ascii 64))
    (category uint)
    (public-profile (optional principal))
    (importance-score uint)
    (notes (string-utf8 500)))
  
  (let ((owner tx-sender)
        (contact-id (get-and-increment-contact-id owner))
        (current-time (unwrap-panic (get-block-info? time u0))))
    
    ;; Validate that importance score is between 1 and 10
    (asserts! (and (>= importance-score u1) (<= importance-score u10)) ERR-INVALID-PARAMS)
    
    ;; Validate that category exists (either standard or custom)
    (asserts! (or 
                (and (>= category u1) (<= category u6)) 
                (is-some (map-get? custom-categories { owner: owner, category-id: category }))
              ) 
              ERR-CATEGORY-NOT-FOUND)
    
    (map-set contacts
      { owner: owner, contact-id: contact-id }
      {
        name: name,
        title: title,
        company: company,
        email: email,
        phone: phone,
        location: location,
        category: category,
        public-profile: public-profile,
        date-added: current-time,
        last-updated: current-time,
        importance-score: importance-score,
        notes: notes
      })
    (ok contact-id)))

;; Update an existing contact's information
(define-public (update-contact
    (contact-id uint)
    (name (string-ascii 64))
    (title (string-ascii 64))
    (company (string-ascii 64))
    (email (string-ascii 64))
    (phone (string-ascii 32))
    (location (string-ascii 64))
    (category uint)
    (public-profile (optional principal))
    (importance-score uint)
    (notes (string-utf8 500)))
  
  (let ((owner tx-sender)
        (current-time (unwrap-panic (get-block-info? time u0))))
    
    ;; Check if contact exists
    (asserts! (contact-exists? owner contact-id) ERR-CONTACT-NOT-FOUND)
    
    ;; Validate that importance score is between 1 and 10
    (asserts! (and (>= importance-score u1) (<= importance-score u10)) ERR-INVALID-PARAMS)
    
    ;; Validate that category exists (either standard or custom)
    (asserts! (or 
                (and (>= category u1) (<= category u6)) 
                (is-some (map-get? custom-categories { owner: owner, category-id: category }))
              ) 
              ERR-CATEGORY-NOT-FOUND)
    
    (map-set contacts
      { owner: owner, contact-id: contact-id }
      {
        name: name,
        title: title,
        company: company,
        email: email,
        phone: phone,
        location: location,
        category: category,
        public-profile: public-profile,
        date-added: (get date-added (unwrap-panic (map-get? contacts { owner: owner, contact-id: contact-id }))),
        last-updated: current-time,
        importance-score: importance-score,
        notes: notes
      })
    (ok true)))

;; Delete a contact from the user's network
(define-public (delete-contact (contact-id uint))
  (let ((owner tx-sender))
    ;; Check if contact exists
    (asserts! (contact-exists? owner contact-id) ERR-CONTACT-NOT-FOUND)
    
    (map-delete contacts { owner: owner, contact-id: contact-id })
    (ok true)))

;; Create a custom category for organizing contacts
(define-public (create-custom-category 
    (name (string-ascii 32)) 
    (description (string-utf8 100)))
  
  (let ((owner tx-sender)
        (category-id (get-and-increment-category-id owner)))
    
    (map-set custom-categories
      { owner: owner, category-id: category-id }
      { 
        name: name,
        description: description
      })
    (ok category-id)))

;; Update a custom category
(define-public (update-custom-category 
    (category-id uint)
    (name (string-ascii 32)) 
    (description (string-utf8 100)))
  
  (let ((owner tx-sender))
    ;; Check if category exists
    (asserts! (is-some (map-get? custom-categories { owner: owner, category-id: category-id }))
              ERR-CATEGORY-NOT-FOUND)
    
    (map-set custom-categories
      { owner: owner, category-id: category-id }
      { 
        name: name,
        description: description
      })
    (ok true)))

;; Delete a custom category
(define-public (delete-custom-category (category-id uint))
  (let ((owner tx-sender))
    ;; Check if category exists
    (asserts! (is-some (map-get? custom-categories { owner: owner, category-id: category-id }))
              ERR-CATEGORY-NOT-FOUND)
    
    (map-delete custom-categories { owner: owner, category-id: category-id })
    (ok true)))

;; Schedule a follow-up reminder for a contact
(define-public (schedule-follow-up
    (contact-id uint)
    (due-date uint)
    (title (string-ascii 64))
    (description (string-utf8 200)))
  
  (let ((owner tx-sender)
        (follow-up-id (get-and-increment-follow-up-id owner))
        (current-time (unwrap-panic (get-block-info? time u0))))
    
    ;; Check if contact exists
    (asserts! (contact-exists? owner contact-id) ERR-CONTACT-NOT-FOUND)
    
    ;; Validate that due date is in the future
    (asserts! (> due-date current-time) ERR-INVALID-PARAMS)
    
    (map-set follow-ups
      { owner: owner, follow-up-id: follow-up-id }
      {
        contact-id: contact-id,
        due-date: due-date,
        title: title,
        description: description,
        completed: false,
        reminder-sent: false
      })
    (ok follow-up-id)))

;; Mark a follow-up as completed
(define-public (complete-follow-up (follow-up-id uint))
  (let ((owner tx-sender))
    (match (map-get? follow-ups { owner: owner, follow-up-id: follow-up-id })
      follow-up (begin
        (map-set follow-ups
          { owner: owner, follow-up-id: follow-up-id }
          (merge follow-up { completed: true })
        )
        (ok true))
      ERR-FOLLOW-UP-NOT-FOUND)))

;; Update a follow-up reminder
(define-public (update-follow-up
    (follow-up-id uint)
    (due-date uint)
    (title (string-ascii 64))
    (description (string-utf8 200)))
  
  (let ((owner tx-sender)
        (current-time (unwrap-panic (get-block-info? time u0))))
    
    ;; Validate that due date is in the future
    (asserts! (> due-date current-time) ERR-INVALID-PARAMS)
    
    (match (map-get? follow-ups { owner: owner, follow-up-id: follow-up-id })
      follow-up (begin
        (map-set follow-ups
          { owner: owner, follow-up-id: follow-up-id }
          (merge follow-up {
            due-date: due-date,
            title: title,
            description: description,
            reminder-sent: false
          })
        )
        (ok true))
      ERR-FOLLOW-UP-NOT-FOUND)))

;; Delete a follow-up reminder
(define-public (delete-follow-up (follow-up-id uint))
  (let ((owner tx-sender))
    (asserts! (is-some (map-get? follow-ups { owner: owner, follow-up-id: follow-up-id }))
              ERR-FOLLOW-UP-NOT-FOUND)
    
    (map-delete follow-ups { owner: owner, follow-up-id: follow-up-id })
    (ok true)))

;; Record an interaction with a contact
(define-public (record-interaction
    (contact-id uint)
    (type (string-ascii 32))
    (notes (string-utf8 500))
    (outcome (string-utf8 200)))
  
  (let ((owner tx-sender)
        (interaction-id (get-and-increment-interaction-id owner))
        (current-time (unwrap-panic (get-block-info? time u0))))
    
    ;; Check if contact exists
    (asserts! (contact-exists? owner contact-id) ERR-CONTACT-NOT-FOUND)
    
    (map-set interactions
      { owner: owner, interaction-id: interaction-id }
      {
        contact-id: contact-id,
        date: current-time,
        type: type,
        notes: notes,
        outcome: outcome
      })
    
    ;; Update last updated timestamp for the contact
    (match (map-get? contacts { owner: owner, contact-id: contact-id })
      contact (map-set contacts
                { owner: owner, contact-id: contact-id }
                (merge contact { last-updated: current-time }))
      ;; This should never happen due to the existence check above
      false)
    
    (ok interaction-id)))

;; Update an interaction record
(define-public (update-interaction
    (interaction-id uint)
    (type (string-ascii 32))
    (notes (string-utf8 500))
    (outcome (string-utf8 200)))
  
  (let ((owner tx-sender))
    (match (map-get? interactions { owner: owner, interaction-id: interaction-id })
      interaction (begin
        (map-set interactions
          { owner: owner, interaction-id: interaction-id }
          (merge interaction {
            type: type,
            notes: notes,
            outcome: outcome
          })
        )
        (ok true))
      ERR-INTERACTION-NOT-FOUND)))

;; Delete an interaction record
(define-public (delete-interaction (interaction-id uint))
  (let ((owner tx-sender))
    (asserts! (is-some (map-get? interactions { owner: owner, interaction-id: interaction-id }))
              ERR-INTERACTION-NOT-FOUND)
    
    (map-delete interactions { owner: owner, interaction-id: interaction-id })
    (ok true)))

;; Update the importance score for a contact
(define-public (update-importance-score (contact-id uint) (importance-score uint))
  (let ((owner tx-sender))
    ;; Validate that importance score is between 1 and 10
    (asserts! (and (>= importance-score u1) (<= importance-score u10)) ERR-INVALID-PARAMS)
    
    (match (map-get? contacts { owner: owner, contact-id: contact-id })
      contact (begin
        (map-set contacts
          { owner: owner, contact-id: contact-id }
          (merge contact { importance-score: importance-score })
        )
        (ok true))
      ERR-CONTACT-NOT-FOUND)))

;; Flag that a reminder notification has been sent
(define-public (mark-reminder-sent (follow-up-id uint))
  (let ((owner tx-sender))
    (match (map-get? follow-ups { owner: owner, follow-up-id: follow-up-id })
      follow-up (begin
        (map-set follow-ups
          { owner: owner, follow-up-id: follow-up-id }
          (merge follow-up { reminder-sent: true })
        )
        (ok true))
      ERR-FOLLOW-UP-NOT-FOUND)))