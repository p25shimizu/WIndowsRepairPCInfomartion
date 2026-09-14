# GitHub 初期登録

GitHub で Private repository を作成後、このフォルダで実行:

```bash
git init
git branch -M main
git add .
git commit -m "Initial import v6.19"
git remote add origin <YOUR_PRIVATE_REPOSITORY_URL>
git push -u origin main
```

その後、`docs/RELEASE_PROCESS.md` に沿って Release を作成してください。

## 推奨

- Repository visibility: **Private**
- 社員は Organization / Team 経由でアクセス
- Branch protection を main に設定
- Secrets は GitHub Secrets または社内の安全な資格情報管理へ
