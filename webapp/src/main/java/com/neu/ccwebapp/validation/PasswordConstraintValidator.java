package com.neu.ccwebapp.validation;

import org.passay.*;

import javax.validation.ConstraintValidator;
import javax.validation.ConstraintValidatorContext;
import java.util.Arrays;
import java.util.stream.Collectors;

public class PasswordConstraintValidator implements ConstraintValidator<ValidPassword, String> {

    @Override
    public void initialize(ValidPassword arg0) {
    }

    @Override
    public boolean isValid(String password, ConstraintValidatorContext context) {
        PasswordValidator validator = new PasswordValidator(Arrays.asList(
                new LengthRule(8, 70),
                new UppercaseCharacterRule(1),
                new SpecialCharacterRule(1),
                new WhitespaceRule()));
        if(password==null)
            return false;
        RuleResult result = validator.validate(new PasswordData(password));
        if (result.isValid()) {
            return true;
        }
        context.disableDefaultConstraintViolation();
        context.buildConstraintViolationWithTemplate(
                validator.getMessages(result).stream().collect(Collectors.joining(",")))
                .addConstraintViolation();
        return false;
    }
}