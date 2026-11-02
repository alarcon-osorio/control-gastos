import Foundation
import Supabase

enum SupabaseConfig {
    static let url = URL(string: "https://yiftfshfetqtgscgvhbc.supabase.co")!
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlpZnRmc2hmZXRxdGdzY2d2aGJjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE5NDM1NTUsImV4cCI6MjEwNzUxOTU1NX0.jzOPCD_QcNxu5mdxkzQ7XXZsGBS6jqDj2dq0Vymf0q4"
}

let supabase = SupabaseClient(
    supabaseURL: SupabaseConfig.url,
    supabaseKey: SupabaseConfig.anonKey
)