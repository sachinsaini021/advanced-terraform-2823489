resource "google_storage_bucket" "gcs_bucket" {
  name                       = "auto-expiring-bucket"
  location                   = "US"
  force_destroy = true
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }


  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_notification" "notification_gcs_bucket" {
  bucket         = google_storage_bucket.gcs_bucket.name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.example_topic.id
  event_types    = ["OBJECT_FINALIZE", "OBJECT_METADATA_UPDATE"]
  custom_attributes = {
    new-attribute = "new-attribute-value"
  }
  depends_on = [google_pubsub_topic_iam_binding.pubsub_binding]
}



resource "google_pubsub_topic" "example_topic" {
  name = "example-topic"
}

resource "google_pubsub_subscription" "example_topic" {
  name  = "example-subscription"
  topic = google_pubsub_topic.example.name

  labels = {
    foo = "bar"
  }

  # 20 minutes
  message_retention_duration = "604800s"
  retain_acked_messages      = true

  ack_deadline_seconds =  120

 dead_letter_policy {
    dead_letter_topic = google_pubsub_topic.example_dead_letter.id
    max_delivery_attempts = 10
  }
}


resource "google_pubsub_topic" "example_dead_letter" {
  name = "example-topic"
}



resource "google_pubsub_topic_iam_binding" "pubsub_binding" {
  project = google_pubsub_topic.example.project
  topic = google_pubsub_topic.example.example_topic
  role = "roles/pubsub.publisher"
  members = [
    "serviceaccount:SA@example.com",
  ]
}