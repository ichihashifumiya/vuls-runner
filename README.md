# vuls-runner

Vuls 実行環境を AWS 上に構築する

## 注意点

### インスタンスサイズは t2.small 以上にすること

メモリが 2GB ないと脆弱性データベースのフェッチに失敗する。

### インスタンスを作成するサブネットは、外部との通信を可能にしておくこと

Internet Gateway, NAT Gateway などで、外部との通信が可能な必要がある。

そうでない場合、

- VulsRepo の閲覧不可
- ssh 不可
- 脆弱性 DB 更新失敗

などの問題が発生する。

## 使い方

### AMI 作成

以下のように作成する。

```
$ packer build -var ssh_ip=`curl -s ifconfig.me`/32 vuls.pkr.hcl
```

AMI のビルドに成功すれば以下のような結果が得られる。

```
Build 'amazon-ebs.levitation_stone' finished after 17 minutes 11 seconds.

==> Wait completed after 17 minutes 11 seconds

==> Builds finished. The artifacts of successful builds are:
--> amazon-ebs.levitation_stone: AMIs were created:
ap-northeast-1: ami-08aaade37251de75a
```

### Vuls サーバー作成

#### `tfstate_backend_config.tfvars` 作成

`-backend-config` に渡すために、 tfstate を配置する S3 バケットに関する情報をまとめたファイルを作成する。

#### `terraform init` 実行

`terraform init` を実行し、 tfstate を初期化する。

```
$ terraform init -backend-config  tfstate_backend_config.tfvars
```

#### 変数ファイル作成

リソースを作成する前に、いくつかの必要事項を埋める必要がある。

対話型インターフェースやコマンドライン引数で与えることも可能だが、利便性からファイル化を推奨する。

必須、もしくはオプションの変数は以下の通りである。

| 変数名 | 必須? | デフォルト | 意味 |
| ----- | ---- | --------- | --- |
| `region` | no | `ap-northeast-1` | リソースを作成するリージョン |
| `profile` | yes | | 利用する AWS アカウントの ARN. |
| `role_arn` | no | | スイッチ先のロール。GitLab CI/CD などから実行する目的で、デプロイユーザーを利用する場合は指定不要。 |
| `vpc_id` | yes | | リソースを作成する VPC の ID |
| `subnet_id` | yes | | リソースを作成するサブネットの ID |
| `ssh_accepted_cidrs` | no | `[]` | ssh を受け入れる IP を CIDR 形式で記述する |
| `ssh_accepted_security_groups` | no | `[]` | ssh を受けいれるセキュリティグループ ID を指定する |
| `http_accepted_cidrs` | no | `[]` | VulsRepo へのアクセスを受け入れる IP を CIDR 形式で指定する |
| `http_accepted_security_groups` | no | `[]` | VulsRepo へのアクセスを受け入れるセキュリティグループ ID を指定する。 ALB からトラフィックを流す想定 |
| `instance_security_group_ids` | no | `[]` | EC2 インスタンスに割り当てるセキュリティグループ ID を指定する。 予めセキュリティグループが作成されている場合に利用する。 |
| `ami_id` | no | null | インスタンスで利用する AMI ID を指定する。指定しなくても packer で作成した最新の AMI を取得する用になっているので、ロールバックや試験用 |
| `instance_type` | no | `t2.small` | インスタンスタイプを指定する。 脆弱性 DB の更新にメモリが 2GB は必要なので `t2.small` 相当以上のインスタンスを推奨 |
| `ec2_user_keyname` | yes | | `ec2-user` として ssh するための鍵名を指定する。 |
| `volume_size` | no | 8 | EC2 のルートボリュームの容量を指定する。デフォルトは 8GB |
| `instance_name` | no | `vuls-runner` | EC2 インスタンス名を指定する |
| `associate_public_ip_address` | no | `false` | EC2 インスタンスにパブリック IP を割り当てるかを指定する。直接アクセスは非推奨なため、基本的に動作確認用 |
| `tags` | no | `{ Project = "vuls-runner" }` | terraform によって作成されるリソースに共通で付与するタグを指定する。 EC2 インスタンス名を変更したい場合は `instance_name` を指定すること |

ファイル名は `terraform.tfvars` もしくは `*.auto.tfvars` に適合するものとすると、`plan` や `apply` 実行時に自動的に読み込まれるため推奨する。

#### `terraform plan` `terraform apply` 実行

まず `terraform plan` を実行し、リソース参照エラーなどが発生しないことを確認する。

```
$ terraform plan
# 略
Plan: 5 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.
```

エラーが無ければ、 `terraform apply` を実行しリソースを作成する。

```
$ terraform apply
# 略
Plan: 5 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_iam_role.vuls_instance_profile: Creating...
aws_security_group.vuls: Creating...
aws_security_group.vuls: Creation complete after 2s [id=sg-0eeec9815f80bdbd1]
aws_iam_role.vuls_instance_profile: Creation complete after 3s [id=vuls-runner-ec2-role]
aws_iam_role_policy.vuls_instance_profile: Creating...
aws_iam_instance_profile.vuls: Creating...
aws_iam_role_policy.vuls_instance_profile: Creation complete after 1s [id=vuls-runner-ec2-role:vuls-runner-ec2-policy]
aws_iam_instance_profile.vuls: Creation complete after 4s [id=vuls-runner-instance-profile]
aws_instance.vuls: Creating...
aws_instance.vuls: Still creating... [10s elapsed]
aws_instance.vuls: Still creating... [20s elapsed]
aws_instance.vuls: Still creating... [30s elapsed]
aws_instance.vuls: Still creating... [40s elapsed]
aws_instance.vuls: Creation complete after 42s [id=i-0b0ce343137f38dba]

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

levitation_stone_instance_id = i-0b0ce343137f38dba
levitation_stone_instance_private_ip = 10.1.96.49
levitation_stone_instance_public_ip = 13.112.75.239
levitation_stone_security_group_id = sg-0eeec9815f80bdbd1
```

##### Outputs について

インスタンスとの連携のためにいくつかの値を出力している。

| 変数名 | 意味 |
| ----- | --- |
| `levitation_stone_instance_id` | EC2 インスタンスの ID。ターゲットグループなどに指定するために使う |
| `levitation_stone_instance_private_ip` | EC2 インスタンスのプライベート IP. 踏み台経由で ssh する場合などに使う |
| `levitation_stone_instance_public_ip` | EC2 インスタンスのパブリック IP. `associate_public_ip_address = true` の場合のみ表示される。 |
| `levitation_stone_security_group_id` | terraform が作成したセキュリティグループの ID. この EC2 インスタンスからのアクセスを許可する際などに使う |

## ログの閲覧方法

packer による脆弱性 DB 更新時のログ、および、 VulsRepo のログは自動的に CloudWatch Logs に転送されている。

packer に関するログは `/ec2/vuls/packer` 以下に、 VulsRepo に関するログは `/ec2/vuls/vulsrepo` 以下にある。
