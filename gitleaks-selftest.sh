#!/usr/bin/env bash
# DO NOT MERGE — self-test fixture for the gitleaks CI gate.
# This branch exists only to verify that the secret-scan workflow
# correctly fails on a planted secret. The string below is freshly
# random openssl(1) output; it is not a real credential.
FAKE_SECRET="xxx9Cz60s3Nmxybc7zktKKDAKAO+Tw+OHf8wf7hngP5pw8+5EjASvTFqrTVSI3YF"
echo "self-test fixture, no real secret"
