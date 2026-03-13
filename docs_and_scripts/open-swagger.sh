#!/bin/bash

# Swagger UI Access Script for Banking Microservices
# This script provides quick access to Swagger documentation for all services

echo "=========================================="
echo "🚀 Banking Microservices - Swagger UI"
echo "=========================================="
echo ""
echo "📚 Access Swagger Documentation:"
echo ""
echo "1️⃣  Auth Service (Port 8083):"
echo "   URL: http://localhost:8083/auth/swagger-ui/index.html"
echo "   API Docs: http://localhost:8083/auth/v3/api-docs"
echo ""
echo "2️⃣  Account Service (Port 8081):"
echo "   URL: http://localhost:8081/swagger-ui/index.html"
echo "   API Docs: http://localhost:8081/v3/api-docs"
echo ""
echo "3️⃣  Transaction Service (Port 8082):"
echo "   URL: http://localhost:8082/swagger-ui/index.html"
echo "   API Docs: http://localhost:8082/v3/api-docs"
echo ""
echo "=========================================="
echo "💡 Usage Tips:"
echo "=========================================="
echo ""
echo "1. First, login via Auth Service to get JWT token:"
echo "   - Use /api/auth/login endpoint"
echo "   - Copy the returned JWT token"
echo ""
echo "2. Authorize in Swagger UI:"
echo "   - Click the 'Authorize' button (🔓)"
echo "   - Paste your JWT token (without 'Bearer' prefix)"
echo "   - Click 'Authorize'"
echo ""
echo "3. Test endpoints:"
echo "   - All endpoints will now include your JWT token"
echo "   - Try 'Try it out' on any endpoint"
echo ""
echo "=========================================="
echo ""

# Check if services are running
echo "🔍 Checking service status..."
echo ""

if pgrep -f "auth.*spring-boot" > /dev/null; then
    echo "✅ Auth Service: RUNNING"
    curl -s http://localhost:8083/auth/swagger-ui/index.html > /dev/null 2>&1 && echo "   Swagger UI: ACCESSIBLE" || echo "   Swagger UI: Loading..."
else
    echo "❌ Auth Service: NOT RUNNING"
fi

if pgrep -f "account.*spring-boot" > /dev/null; then
    echo "✅ Account Service: RUNNING"
    curl -s http://localhost:8081/swagger-ui/index.html > /dev/null 2>&1 && echo "   Swagger UI: ACCESSIBLE" || echo "   Swagger UI: Loading..."
else
    echo "❌ Account Service: NOT RUNNING"
fi

if pgrep -f "transaction.*spring-boot" > /dev/null; then
    echo "✅ Transaction Service: RUNNING"
    curl -s http://localhost:8082/swagger-ui/index.html > /dev/null 2>&1 && echo "   Swagger UI: ACCESSIBLE" || echo "   Swagger UI: Loading..."
else
    echo "❌ Transaction Service: NOT RUNNING"
fi

echo ""
echo "=========================================="
echo "🌐 Opening Swagger UI in browser..."
echo "=========================================="
echo ""

# Try to open in default browser
if command -v xdg-open > /dev/null; then
    xdg-open "http://localhost:8083/auth/swagger-ui/index.html" 2>/dev/null &
    sleep 1
    xdg-open "http://localhost:8081/swagger-ui/index.html" 2>/dev/null &
    sleep 1
    xdg-open "http://localhost:8082/swagger-ui/index.html" 2>/dev/null &
    echo "✅ Opened Swagger UI in your default browser!"
else
    echo "⚠️  Please manually open the URLs above in your browser"
fi

echo ""
echo "=========================================="
echo "📖 Common API Workflows:"
echo "=========================================="
echo ""
echo "1. Register User → Login → Get Token"
echo "2. Create Customer (CIF) → Update KYC Status"
echo "3. Create Account → Credit/Debit/Transfer"
echo "4. View Transaction History"
echo ""
echo "Happy Testing! 🎉"
echo ""
