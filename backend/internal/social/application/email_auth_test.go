package application_test

import (
	"errors"
	"testing"

	memrepo "github.com/Jeudry/memorizar/backend/internal/social/adapters/memory"
	"github.com/Jeudry/memorizar/backend/internal/social/application"
)

func newSvc() *application.Service {
	return application.NewService(memrepo.NewRepository())
}

func TestRegisterEmail_HappyPath(t *testing.T) {
	s := newSvc()
	out, err := s.RegisterEmail(application.EmailRegisterInput{
		Email: "test@dev.local", Password: "abcdefgh", DisplayName: "T", Username: "test_user", Age: 25,
	})
	if err != nil {
		t.Fatalf("register: %v", err)
	}
	if out.User.PasswordHash != "" {
		t.Error("PasswordHash filtrado en respuesta")
	}
	if out.Session.Token == "" {
		t.Error("session sin token")
	}
}

func TestRegisterEmail_WeakPassword(t *testing.T) {
	s := newSvc()
	_, err := s.RegisterEmail(application.EmailRegisterInput{
		Email: "x@dev.io", Password: "short", DisplayName: "X", Username: "weak_pw_user", Age: 25,
	})
	if !errors.Is(err, application.ErrWeakPassword) {
		t.Errorf("got %v", err)
	}
}

func TestRegisterEmail_DuplicateEmail(t *testing.T) {
	s := newSvc()
	in := application.EmailRegisterInput{
		Email: "dup@dev.io", Password: "abcdefgh", DisplayName: "D", Username: "dup_user", Age: 25,
	}
	if _, err := s.RegisterEmail(in); err != nil {
		t.Fatal(err)
	}
	_, err := s.RegisterEmail(in)
	if !errors.Is(err, application.ErrEmailInUse) {
		t.Errorf("got %v", err)
	}
}

func TestLoginEmail_HappyPath(t *testing.T) {
	s := newSvc()
	in := application.EmailRegisterInput{
		Email: "login@dev.io", Password: "abcdefgh", DisplayName: "L", Username: "login_user", Age: 25,
	}
	if _, err := s.RegisterEmail(in); err != nil {
		t.Fatal(err)
	}
	out, err := s.LoginEmail(application.EmailLoginInput{
		Email: "login@dev.io", Password: "abcdefgh",
	})
	if err != nil || out == nil {
		t.Fatalf("login: %v", err)
	}
	if out.User.Email != "login@dev.io" {
		t.Errorf("got %+v", out.User)
	}
}

func TestLoginEmail_WrongPassword(t *testing.T) {
	s := newSvc()
	_, _ = s.RegisterEmail(application.EmailRegisterInput{
		Email: "x@dev.io", Password: "abcdefgh", DisplayName: "X", Username: "wrong_pw_user", Age: 25,
	})
	_, err := s.LoginEmail(application.EmailLoginInput{Email: "x@dev.io", Password: "wrong-pwd-xx"})
	if !errors.Is(err, application.ErrInvalidCredentials) {
		t.Errorf("got %v", err)
	}
}

func TestPasswordResetFlow(t *testing.T) {
	s := newSvc()
	in := application.EmailRegisterInput{
		Email: "reset@dev.io", Password: "originalpw", DisplayName: "R", Username: "reset_user", Age: 25,
	}
	if _, err := s.RegisterEmail(in); err != nil {
		t.Fatal(err)
	}
	token, err := s.RequestPasswordReset("reset@dev.io")
	if err != nil || token == "" {
		t.Fatalf("request: %v %s", err, token)
	}
	if err := s.ConfirmPasswordReset(token, "newpassword123"); err != nil {
		t.Fatalf("confirm: %v", err)
	}
	if _, err := s.LoginEmail(application.EmailLoginInput{Email: "reset@dev.io", Password: "originalpw"}); err == nil {
		t.Error("old password should fail")
	}
	if _, err := s.LoginEmail(application.EmailLoginInput{Email: "reset@dev.io", Password: "newpassword123"}); err != nil {
		t.Errorf("new password failed: %v", err)
	}
}
