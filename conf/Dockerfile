FROM photon:3.0

LABEL author="Jonathan.Zollinger@outlook.com"
LABEL description="Docker image with Jonathan Zollinger's preconfigured powershell profile"

ENV TERM linux

WORKDIR /root

# Set terminal. If we don't do this, weird readline things happen.
RUN echo "/usr/bin/pwsh" >> /etc/shells && \
    echo "/bin/pwsh" >> /etc/shells && \
    tdnf install -y wget tar icu powershell-7.1.5-3.ph3 git unzip tzdata && \
    pwsh -c "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted" && \
    pwsh -c "Install-Module -Name PSDesiredStateConfiguration" && \
    pwsh -c "Enable-ExperimentalFeature PSDesiredStateConfiguration.InvokeDscResource" && \
    tdnf clean all
# TODO (Jonathan) download profile from this repo and add it to /root/.config/powershell/

CMD ["/bin/pwsh"]
