resource "aws_instance" "tomcat" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  security_groups             = [aws_security_group.tomcat_sg.name]
  key_name                    = aws_key_pair.tomcat_key.key_name
  
  user_data                   = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y java-17-amazon-corretto-headless
              sudo groupadd tomcat
              sudo useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat
              wget -O tomcat.tar.gz https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.49/bin/apache-tomcat-10.1.49.tar.gz
              sudo mkdir /opt/tomcat
              sudo tar xzf tomcat.tar.gz -C /opt/tomcat --strip-components=1
              sudo chown -R tomcat:tomcat /opt/tomcat
              sudo sh -c 'chmod +x /opt/tomcat/bin/*.sh'
              sudo echo "
                    [Unit]
                    Description=Apache Tomcat Web Application Container
                    After=network.target

                    [Service]
                    Type=forking
                    User=tomcat
                    Group=tomcat
                    Environment="JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto"
                    Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
                    Environment="CATALINA_HOME=/opt/tomcat"
                    Environment="CATALINA_BASE=/opt/tomcat"
                    ExecStart=/opt/tomcat/bin/startup.sh
                    ExecStop=/opt/tomcat/bin/shutdown.sh

                   [Install]
                   WantedBy=multi-user.target
                " >> /etc/systemd/system/tomcat.service
              sudo systemctl daemon-reload
              sudo systemctl start tomcat
              sudo systemctl enable tomcat

              EOF
  tags = {
    Name = "tomcatServerInstance"
  }

}

resource "aws_security_group" "tomcat_sg" {
  name        = "tomcat_sg"
  description = "Allow HTTP and SSH traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

}

resource "aws_key_pair" "tomcat_key" {
  key_name   = "tomcat_key"
  public_key = file("~/.ssh/id_rsa.pub")
}
