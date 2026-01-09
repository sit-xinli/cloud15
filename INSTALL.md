# Windows 環境構築ガイド (AWS CLI & Terraform)

このガイドでは、Windows OS を使用している方向けに、このプロジェクトを実行するために必要なツール（AWS CLI と Terraform）のインストール手順を解説します。

初心者の方でも簡単にセットアップできるよう、Windows 標準の機能を使った方法をメインに紹介します。

## 📋 準備するもの

*   Windows 10 (バージョン 1709 以降) または Windows 11
*   インターネット接続
*   管理者権限（ソフトをインストールするために必要です）
*   AWS アカウントのアクセスキーとシークレットキー

---

## 🚀 方法1: コマンド一発でインストール (推奨)

Windows 10/11 に標準搭載されている `winget` (アプリインストーラー) というツールを使うと、面倒なダウンロードや設定を自動で行えます。

### 1. PowerShell を管理者として起動する
1.  **スタートボタン**（Windowsロゴ）を右クリックします。
2.  **「ターミナル (管理者)」** または **「Windows PowerShell (管理者)」** をクリックします。
3.  「このアプリがデバイスに変更を加えることを許可しますか？」と出たら **「はい」** をクリックします。

### 2. インストールコマンドを実行する
開いた青い（または黒い）画面に、以下のコマンドをコピー＆ペーストして Enter キーを押してください。

**Terraform のインストール:**
```powershell
winget install HashiCorp.Terraform
```

**AWS CLI のインストール:**
```powershell
winget install Amazon.AWSCLI
```

※ 途中で「同意しますか？」のようなメッセージが出たら、`Y` を入力して Enter を押してください。

### 3. 画面を閉じて開き直す
インストールが終わったら、**一度 PowerShell の画面を閉じてください**。
再度 PowerShell を開く（今度は管理者でなくてもOK）ことで、インストールしたツールが使えるようになります。

---

## 📦 方法2: 公式サイトから手動でインストール

上記の方法がうまくいかない場合は、こちらの手順を試してください。

### 1. AWS CLI のインストール
1.  [AWS CLI 公式インストーラー (64-bit)](https://awscli.amazonaws.com/AWSCLIV2.msi) をダウンロードします。
2.  ダウンロードしたファイル (`AWSCLIV2.msi`) をダブルクリックして実行します。
3.  画面の指示に従って「Next」をクリックしていけば完了です。

### 2. Terraform のインストール
Terraform はインストーラーがなく、少し手順が特殊です。

1.  [Terraform ダウンロードページ](https://developer.hashicorp.com/terraform/downloads) にアクセスし、Windows 用の **AMD64** ボタンをクリックして ZIP ファイルをダウンロードします。
2.  Cドライブの直下などに `terraform` というフォルダを作ります（例: `C:\terraform`）。
3.  ダウンロードした ZIP ファイルの中にある `terraform.exe` を、作成したフォルダ（`C:\terraform`）の中にコピーします。
4.  **パス(Path)を通す**:
    *   Windows の検索バーで「環境変数」と入力し、「システム環境変数の編集」を開きます。
    *   「環境変数」ボタンをクリックします。
    *   「システム環境変数」のリストから `Path` を探して選択し、「編集」をクリックします。
    *   「新規」をクリックし、さきほどのフォルダの場所 `C:\terraform` を入力して「OK」をすべて押して閉じます。

---

## ✅ インストール確認

PowerShell を開き、以下のコマンドを入力してバージョン番号が表示されれば成功です。

```powershell
# AWS CLI の確認
aws --version
# 表示例: aws-cli/2.15.0 ...

# Terraform の確認
terraform --version
# 表示例: Terraform v1.7.0 ...
```

---

## 🔑 AWS 初期設定

ツールがインストールできたら、AWS アカウントの認証情報を登録します。
まだアクセスキーを持っていない場合は、AWS コンソールの IAM 画面から作成してください（または管理者に確認してください）。

1.  PowerShell で以下のコマンドを実行します。

```powershell
aws configure
```

2.  以下のように情報の入力を求められるので、順番に入力して Enter を押します。入力した文字（パスワードなど）は画面に表示されない場合がありますが、そのまま入力してください。

```text
AWS Access Key ID [None]: (あなたのアクセスキーを入力)
AWS Secret Access Key [None]: (あなたのシークレットキーを入力)
Default region name [None]: us-east-1
Default output format [None]: json
```
※ `us-east-1` はこのプロジェクトのデフォルトリージョンです。必要に応じて変更してください（例: `ap-northeast-1` 東京）。

## 🏁 プロジェクトの開始方法

インストールと設定が完了したら、このプロジェクトを開始できます。

1.  PowerShell でこのプロジェクトのフォルダに移動します。
    ```powershell
    cd パス\to\cloud15
    ```
2.  Terraform を初期化します。
    ```powershell
    terraform init
    ```
3.  インフラを作成します。
    ```powershell
    terraform apply
    ```

トラブルが発生した場合は、`README.md` のトラブルシューティングセクションも参照してください。
