################################
# IAM Role for EKS Admin
################################

resource "aws_iam_role" "eks_admin_role" {
  name = "eks-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

################################
# Attach EKS Policies
################################

resource "aws_iam_policy" "eks_admin_policy" {
  name        = "eks-admin-policy"
  path        = "/"
  description = "EKS Admin Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_admin_policy_attach" {
  role       = aws_iam_role.eks_admin_role.name
  policy_arn = aws_iam_policy.eks_admin_policy.arn
}

################################
# Instance Profile (REQUIRED)
################################

resource "aws_iam_instance_profile" "eks_admin_profile" {
  name = "eks-admin-instance-profile"
  role = aws_iam_role.eks_admin_role.name
}

################################
# Key Pair (PEM file)
################################




################################
# Security Group for Bastion
################################

resource "aws_security_group" "bastion_sg" {
  name        = "eks-bastion-sg"
  description = "SSH access for EKS bastion"
  vpc_id      = aws_vpc.eks_vpc.id

  ingress {
    description = "SSH access (lock to your IP in prod)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-bastion-sg"
  }
}

################################
# EC2 Bastion / Jenkins Instance
################################

resource "aws_instance" "eks_bastion" {
  ami                         = "ami-03f4878755434977f" # Ubuntu 22.04
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet_1.id
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.bastion_sg.id
  ]

  iam_instance_profile = aws_iam_instance_profile.eks_admin_profile.name
  key_name             = "eks-bastion-key"  # EXISTING KEY

  tags = {
    Name = "eks-bastion"
    Role = "eks-admin"
  }
}

################################
# Outputs
################################

output "bastion_public_ip" {
  value = aws_instance.eks_bastion.public_ip
}

output "eks_admin_role" {
  value = aws_iam_role.eks_admin_role.name
}
