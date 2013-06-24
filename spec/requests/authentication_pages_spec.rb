require 'spec_helper'

describe "AuthenticationPages" do
    subject { page }
    
    describe "signin page" do
        before { visit signin_path }
        
        it { should have_selector('h1', text: 'Sign in') }
        it { should have_selector('title', text: 'Sign in') }
    end
    
    describe "signin" do
        before { visit signin_path }
        
        describe "with invalid information" do
            before { click_button "Sign in" }
            
            it { should have_selector('title', text: 'Sign in') }
            it { should have_selector('div.alert.alert-error', text: 'Invalid') }
            
            describe "after visit another page" do
                before { click_link "Home" }
                
                it { should_not have_selector('div.alert.alert-error') }
            end
        end
        
        describe "with valid information" do
            let(:user) { FactoryGirl.create(:user) }
            before { fill_and_submit_signin_form(user) }
            
            it { should have_selector('title', text: user.name) }
            it { should have_link('Users', href: users_path) }
            it { should have_link('Profile', href: user_path(user)) }
            it { should have_link('Settings', href: edit_user_path(user)) }
            it { should have_link('Sign out', href: signout_path) }
            it { should_not have_link('Sign in', href: signin_path) }
            
#             describe "followed by sign out" do
#                 before { click_link 'Sign out' }
#                 it { should have_link 'Sign in' }
#             end
        end
    end

    describe "authorization" do
        
        describe "for non-signed-in users" do
            let(:user) { FactoryGirl.create(:user) }
            
            it { should_not have_link('Profile') }
            it { should_not have_link('Settings') }
            
            describe "in the User controller" do
                
                describe "visiting the edit page" do
                    before { visit edit_user_path(user) }
                    it { should have_selector('title', text: 'Sign in') }
                end
                
                describe "submitting to the update action" do
                    before { put user_path(user) }
                    specify { response.should redirect_to(signin_path) }
                end
                
                describe "visiting the user index" do
                    before { visit users_path }
                    it { should have_selector('title', text: 'Sign in') }
                end
            end
            
            describe "when attempting to visit a protected page" do
                before do 
                    visit edit_user_path(user)
                    fill_in "Email",    with: user.email
                    fill_in "Password", with: user.password
                    click_button "Sign in"
                end
                
                describe "after signing in" do
                    it "should render the desired protected page" do
                        page.should have_selector('title', text: 'Edit user')
                    end
                    
                    describe "when signing in a gain" do
                        before do
                            visit signin_path
                            fill_in "Email",    with: user.email
                            fill_in "Password", with: user.password
                            click_button "Sign in"
                        end
                        
                        it "should render the default (profile) page" do
                            page.should have_selector('title', text: user.name)
                        end
                    end                        
                end
            end
        end
        
        describe "as wrong user" do
            let(:user) { FactoryGirl.create(:user) }
            let(:wrong_user) { FactoryGirl.create(:user, email: "wrong@example.com") }
            
            before { fill_and_submit_signin_form user }
            
            describe "visiting Users#edit page" do
                before { visit edit_user_path(wrong_user) }
                it { should_not have_selector('title', text: full_title('Edit user')) }
            end
            
            describe "submitting a PUT request to the Users#update action" do
                before { put user_path(wrong_user) }
                specify { response.should redirect_to(root_path) }
            end
        end
    
        describe "as non-admin user" do
            let(:user) { FactoryGirl.create(:user) }
            let(:non_admin) { FactoryGirl.create(:user) }
            
            before { fill_and_submit_signin_form(non_admin) }
            
            describe "submitting a DELETE request to the User#destroy action" do
                before { delete user_path(user) }
                specify { response.should redirect_to(root_path) }
            end
        end
        
        describe "as signed in user" do
            let(:user) { FactoryGirl.create(:user) }
            
            before { fill_and_submit_signin_form(user) }
            
            describe "access sign up page" do
                before { get signup_path }
                specify { response.should redirect_to(root_path) }
            end
            
            describe "try to create a new user" do
                before { put signup_path }
                specify { response.should redirect_to(root_path) }
            end
        end
        
        describe "as admin user" do
            let(:admin) { FactoryGirl.create(:admin) }
            
            before { fill_and_submit_signin_form(admin) }
            
            describe "should not delete itself" do                
                before do                    
                    delete user_path(admin)
                end
                
                specify { User.find(admin) != nil }
            end
        end
    end
end
