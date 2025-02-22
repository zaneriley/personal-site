

# Replace 'your_github_webhook_secret' with the actual secret
SECRET="V/cR1ORkr+Fi5FHCzmzoEtgud7Tjdg/7ZS+DTOdzX2qm+LEwve3XkKwqoXAfTvCH"

# Sample payload (you may need to adjust this based on your specific needs)
PAYLOAD='{"ref":"refs/heads/main","commits":[{"added":["case-study/helping-people-find-healthcare/en.md"],"modified":["content/note/test-post.md"],"removed":[]}]}'

# Calculate the signature
SIGNATURE=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$SECRET" | sed 's/^.* //')

# Send the request
curl -X POST \
  http://localhost:8000/api/v1/content/push \
  -H "Content-Type: application/json" \
  -H "X-Hub-Signature-256: sha256=$SIGNATURE" \
  -H "X-GitHub-Event: push" \
  -d "$PAYLOAD"