# FocusGuard Reproducible Development & Build Container
# Base image pinned to official Flutter CI image with Android SDK 34 and OpenJDK 17
FROM ghcr.io/cirruslabs/flutter:3.24.3

LABEL maintainer="FocusGuard Architecture Team"
LABEL description="Zero-Host-Install reproducible development environment for FocusGuard"

ENV DEBIAN_FRONTEND=noninteractive
ENV WORKSPACE=/workspace

WORKDIR ${WORKSPACE}

# Ensure git safe directory for root user in container
RUN git config --global --add safe.directory ${WORKSPACE}

# Pre-accept Android licenses
RUN yes | flutter doctor --android-licenses 2>/dev/null || true

# Verify environment
RUN flutter doctor -v

CMD ["bash"]
