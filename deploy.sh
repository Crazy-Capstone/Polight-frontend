#!/bin/bash
set -e

flutter build web --release
cp vercel.json build/web/
cp -r .vercel build/web/

cd build/web
npx vercel --prod --yes
