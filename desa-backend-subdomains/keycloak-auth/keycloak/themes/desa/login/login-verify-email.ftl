<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <title>Verify Your Email | Dlula</title>
	
	<link rel="icon" type="image/png" href="${url.resourcesPath}/img/favicon.png">
    <link rel="stylesheet" href="${url.resourcesPath}/css/bootstrap.min.css">

    <link rel="stylesheet" href="${url.resourcesPath}/css/style.css">

    <link rel="stylesheet" href="${url.resourcesPath}/css/bootstrap-icons.css">
</head>

<body class="d-flex flex-column min-vh-100">

<div class="container flex-grow-1 d-flex align-items-center">
    <div class="row justify-content-center w-100">
        <div class="col-md-6 col-lg-5">

            <div class="card shadow rounded-4 border-0">
                <div class="card-body p-4 p-md-5">

		
		    <div class="text-center mb-4">
                        <img src="${url.resourcesPath}/img/desa-logo.png" alt="DESA" class="img-fluid mb-3" style="max-height: 120px;">
                        <h4 class="fw-bold">Verify Your Email Address</h4>
                        
                        <p class="text-muted mb-0">
                            Your account must be verified before you can continue.
                        </p>
                    </div>	

                    <#if message?has_content>
                        <div class="alert
                            <#if message.type = 'success'>
                                alert-success
                            <#elseif message.type = 'warning'>
                                alert-warning
                            <#else>
                                alert-danger
                            </#if>
                            text-center">

                            ${kcSanitize(message.summary)?no_esc}
                        </div>
                    </#if>

                    <div class="alert alert-info text-center">
                        <i class="bi bi-info-circle me-1"></i>

                        A verification link will be sent to:

                        <#if user?? && user.email??>
                            <div class="fw-bold mt-2">
                                ${user.email}
                            </div>
                        <#else>
                            <div class="mt-2">
                                your registered email address
                            </div>
                        </#if>
                    </div>

                    <form
                        id="kc-verify-email-form"
                        action="${url.loginAction}"
                        method="post">

                        <div class="d-grid gap-2">
                            <button
                                type="submit"
                                name="submitAction"
                                value="resend"
                                class="btn btn-primary">

                                <i class="bi bi-send me-1"></i>
                                Send verification email
                            </button>
                        </div>
                    </form>

                    <#if client?? && client.baseUrl??>
                        <div class="text-center mt-3 backto">
                            <a href="${client.baseUrl}" class="text-decoration-none">
				<i class="bi bi-arrow-left me-1"></i>
                                Back to application
                            </a>
                        </div>
                    </#if>

                </div>
            </div>

        </div>
    </div>
</div>

<footer class="site-footer">
    <div class="site-footer-inner">
        <img src="${url.resourcesPath}/img/dsti-footer.jpg" alt="Department of Science, Technology and Innovation" class="site-footer-logo site-footer-logo--sti">
        <p class="site-footer-copyright">Copyright © ${.now?string("yyyy")} SANSA. All rights reserved.</p>
        <img src="${url.resourcesPath}/img/sansa-footer.png" alt="SANSA" class="site-footer-logo">
    </div>
</footer>

<script src="${url.resourcesPath}/js/bootstrap.bundle.min.js"></script>
</body>
</html>
