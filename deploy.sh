#!/bin/bash

# Script to deploy the application to Netlify

echo "🚀 Starting deployment process..."
echo ""

# Check if netlify-cli is installed
if ! command -v netlify &> /dev/null; then
    echo "📦 Installing Netlify CLI..."
    npm install -g netlify-cli
fi

# Build the application
echo "🔨 Building application..."
npm run build

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build successful!"
echo ""
echo "📤 Ready to deploy to Netlify"
echo ""
echo "To deploy, run ONE of the following:"
echo ""
echo "Option 1: Deploy to existing site (recommended)"
echo "  netlify deploy --prod --dir=dist --site=wonderful-kringle-a84cac"
echo ""
echo "Option 2: Link and deploy"
echo "  netlify link"
echo "  netlify deploy --prod --dir=dist"
echo ""
echo "Option 3: Manual drag & drop"
echo "  1. Go to: https://app.netlify.com/sites/wonderful-kringle-a84cac/deploys"
echo "  2. Drag the 'dist' folder to the upload area"
echo ""
echo "⚠️  Note: You need to be logged in to Netlify first"
echo "   Run: netlify login"
