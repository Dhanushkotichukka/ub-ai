# OwlCoder AI — Render Deployment & Production Setup Guide

This guide walks you through deploying the OwlCoder AI Backend to Render and setting up MongoDB Atlas for production.

---

## Step 1: MongoDB Atlas Setup

1. Log in to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas).
2. Create a new Cluster (the free tier `M0` works for testing).
3. Under **Database Access**, create a new Database User. Keep the username and auto-generated password handy.
4. Under **Network Access**, add `0.0.0.0/0` to allow connections from anywhere (this is required for Render deployments, as Render IPs are dynamic).
5. Click **Connect** on your cluster, select **Connect your application**, and copy the connection string.
   - It will look like: `mongodb+srv://<username>:<password>@cluster0.mongodb.net/?retryWrites=true&w=majority`
   - Replace `<password>` with the user password you created.

---

## Step 2: Push to GitHub

Ensure all recent backend code (including `render.yaml` and `package.json` updates) is pushed to your GitHub repository. Render will automatically pull from here.

\`\`\`bash
git add .
git commit -m "chore: Prepare production deployment configs"
git push origin main
\`\`\`

---

## Step 3: Render Deployment

1. Log in to [Render.com](https://render.com).
2. Click **New +** and select **Blueprint**.
3. Connect your GitHub repository.
4. Render will automatically detect the `render.yaml` file located in `backend/render.yaml` (if your repo is monorepo, you may need to specify the Root Directory as `backend`).
5. Render will prompt you to enter the **Environment Variables** (which were set to `sync: false` in the blueprint for security).

### Environment Variables to Provide:

You can refer to the \`backend/.env.production.example\` for formatting. At a minimum, provide:

| Key | Description | Example |
|---|---|---|
| `MONGODB_URI` | Your Atlas connection string | `mongodb+srv://user:pass@cluster.net...` |
| `JWT_SECRET` | Random string for auth | `(Use any long random string)` |
| `JWT_REFRESH_SECRET`| Random string for refresh | `(Use any long random string)` |
| `GEMINI_API_KEY` | Real Gemini API key | `AIzaSyB...` |
| `CLIENT_URL` | Frontend URL for CORS | `https://your-frontend-url.com` |

> *Note: For the Chrome Extension to work later, you will eventually update `CLIENT_URL` or Render CORS to allow the extension ID. But for now, just the frontend URL is enough.*

6. Click **Apply**.
7. Render will begin building the application (`npm install`) and then start it (`npm start`).

---

## Step 4: Verification

1. Once Render says **Live**, copy your Render URL (e.g., `https://owlcoder-backend.onrender.com`).
2. Verify the health check by navigating to:
   \`https://your-render-url.onrender.com/health\`
3. You should see a JSON response:
   \`\`\`json
   {
     "status": "ok",
     "service": "OwlCoder AI Backend",
     "version": "1.0.0"
   }
   \`\`\`

---

## Troubleshooting

- **Server Crashing on Start?**
  - Check the Render logs. Usually, this means the `MONGODB_URI` is incorrect or Network Access (`0.0.0.0/0`) isn't configured in Atlas.
- **CORS Errors in Frontend?**
  - Ensure the `CLIENT_URL` environment variable in Render exactly matches the URL you are running the frontend from (no trailing slashes).
- **AI Coach / Reports Failing?**
  - Double check that the `GEMINI_API_KEY` is valid.

---

Once the backend is live and healthy, provide the **Render Deployment URL** back to the console to proceed with Chrome Extension development!
