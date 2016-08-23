module Bank
	
	class Account
		@@used_ids=[]
		attr_reader :balance
		
		def initialize(balance)
			raise ArgumentError, "You cannot open a bank account with a negative balance" unless balance>0
			@balance=balance
			@id=generate_id
			puts "You have a new bank account with id: #{@id} balance: $#{balance}"
		end

		def generate_id
			potential_id=rand(1111111..9999999).to_s
			until not (@@used_ids.include?(potential_id))  do #generate ids until you get unused one
				potential_id=rand(111111..999999).to_s
			end
			@@used_ids<< potential_id
			return potential_id
		end

		def withdraw(amount)
			potential_balance=@balance-amount
			if potential_balance<0
				puts "Sorry, this withdrawl will cause the account to have a negative balance. Your current balance is: $#{@balance} please try again."
				return balance
			else
				return @balance-=amount
			end
		end

		def deposit(amount)
			return @balance+=amount
		end
	end
end

my_account=Bank::Account.new(300)
my_account.withdraw(301)
account2=Bank::Account.new(80000)
account2.deposit(40)